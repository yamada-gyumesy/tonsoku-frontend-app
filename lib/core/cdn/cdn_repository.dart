import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/network/cdn_client.dart';
import 'package:tonsoku/core/storage/json_cache.dart';

/// 配信データの取得口。画面はここより下（`CdnClient` / `JsonCache`）を直接触らない。
///
/// ## stale-while-revalidate
///
/// [watch] はキャッシュがあれば**先にそれを流し**、続けてネットワークから取り直した
/// 値を流す。電波の悪い場所でも一覧が即座に出ることを優先する作りで、Web の
/// 「静的爆速」に相当する体験をアプリ側で担保するのがねらい。
///
/// ## 取り直しは必ず走らせる。ただし変わったかどうかだけを聞く
///
/// **「キャッシュがあれば取り直さない」取得口は置かない。** 以前 `fetchOnce` が
/// あり、関連記事のメタがそれで解決されていた。配信が一時的に崩れた瞬間の本文を
/// 掴むと、**配信が直ってもアプリは永久に壊れた行を出し続ける**（実機で発生。
/// 再インストール以外に直す手が無かった）。**記事は後から直されるので、
/// 取り直しは必ず要る。**
///
/// **一方で毎回まるごと落とすと R2 に無駄がかかる。** そこで持っている `ETag` を
/// `If-None-Match` に載せて聞き、**変わっていなければ 304 が返って本文は流れない**
/// （実測 0 バイト。`feed.json` の 200KB 超も同じ）。キャッシュは強く持ったまま、
/// 直った配信には必ず追随する。
///
/// **ネットワークが失敗してもキャッシュを流し終えていればエラーにしない。**
/// ここでエラーを流すと、キャッシュを見せた直後に画面がエラー表示へ差し替わる。
/// 逆にキャッシュが無ければ失敗はそのまま流す（何も出せないので隠す意味がない）。
class CdnRepository {
  CdnRepository({required this._client, required this._cache});

  /// **取り直した直後の二重取得を防ぐ窓。**
  ///
  /// 引っ張って更新・アクティブ復帰は [fetchFresh] でキャッシュを温めてから
  /// provider を貼り直す。貼り直された `watch()` はキャッシュを流した後もう一度
  /// 取りに行くので、この窓が無いと**1 回の取り直しで全パスを 2 回 GET する**
  /// （5 パスなら 10 回）。
  ///
  /// 通常の画面遷移では効かない長さにしてある（数十秒の離脱で戻った時は
  /// 取り直す）。**長くすると stale-while-revalidate が効かなくなる**ので伸ばさない。
  static const freshWindow = Duration(seconds: 10);

  final CdnClient _client;
  final JsonCache _cache;

  /// [decode] は本文（JSON 文字列 / Markdown）を受け取って値を組み立てる。
  /// **パースに失敗したキャッシュは無視して取得へ進む**——配信データの形が変わった
  /// 後にアプリを更新した時、古いキャッシュで画面が壊れ続けるのを避けるため。
  Stream<T> watch<T>(String path, T Function(String body) decode) async* {
    var servedFromCache = false;

    final cached = await _cache.read(path);
    if (cached != null) {
      try {
        yield decode(cached.body);
        servedFromCache = true;
      } on Object {
        // 壊れた・古い形のキャッシュ。取得側に任せる
      }

      // 取り直した直後なら、もう一度取りに行かない（[freshWindow] 参照）。
      //
      // **経過が負のものは窓に入れない。** 端末の時計が進んでいた時に書いた
      // キャッシュは `fetchedAt` が未来になり、時計を直した後もそのぶん
      // ずっと「取ったばかり」と判定されてしまう。
      //
      // **`servedFromCache` を条件に入れておくこと。** 外すと、壊れたキャッシュが
      // 窓の内側にある時に 1 件も流さないまま完了し、画面が永久に読み込み中になる。
      final elapsed = clock.now().difference(cached.fetchedAt);
      if (servedFromCache &&
          elapsed >= Duration.zero &&
          elapsed < freshWindow) {
        return;
      }
    }

    final T value;
    final CdnPayload payload;
    try {
      // **持っている `ETag` を載せて聞く。** 変わっていなければ 304 が返って
      // 本文は流れない（[CdnClient.fetch]）。
      //
      // **キャッシュを流せなかった時は載せない。** 封筒は無事でも中身が
      // decode できないことがある（必須項目を足したアプリを配った後など）。
      // その状態で「変わっていないか」を聞くと、配信が変わっていない限り
      // 304 が返り、**1 件も流さないままストリームが閉じて画面が永久に
      // 読み込み中になる**（キャッシュも `ETag` もそのままなので、再起動
      // しても `invalidate` しても同じ）。**使えなかったのだから本文を貰う。**
      payload = await _client.fetch(
        path,
        etag: servedFromCache ? cached?.etag : null,
      );
      if (payload.notModified) {
        // **変わっていないことを確かめた事実を残す。** 残さないと
        // `fetchedAt` が古いままで、次の表示でまた問い合わせる
        await _touchCacheQuietly(path);
        return;
      }
      value = decode(payload.body);
    } on Object {
      if (!servedFromCache) rethrow;
      return;
    }

    // **デコードが通ってから書く。** 先に書くと、壊れた配信データをキャッシュに
    // 焼き付けてしまい、オフライン時にそれを読み続ける（decode は上の try の中に
    // あるので、失敗すればここへ来ない）。
    //
    // **書き込みは yield より前に置くこと。** `async*` の `yield` は、購読側が
    // 値を受け取った直後に解除するとそこで生成関数が終わり、**後続の `await` が
    // 実行されない**。`first` / `take(2)` / `await for` + `break` がそれで、
    // とくに `take(2)` はこのストリームが 2 回 yield する以上むしろ自然な書き方。
    // 後ろに置くと「値は返るのにキャッシュだけ残らない」——そのパスの
    // stale-while-revalidate が黙って永久に効かなくなる。
    //
    // 書き込み失敗で取得できた値を捨てないという要件は、`_writeCacheQuietly()` が
    // 例外を飲むことで満たしている（順序ではなく握り潰しで担保する）。
    await _writeCacheQuietly(path, payload.body, etag: payload.etag);

    yield value;
  }

  /// キャッシュへの書き込み失敗は表示を妨げない。次回の取得で書き直せる。
  ///
  /// **ここは自然回復しない障害（容量不足・書き込み権限）が出うる唯一の場所で、
  /// かつ今は完全に見えなくなっている。** アプリにはまだログの仕組みが無いため、
  /// 観測手段は別 Issue で入れる。入れる時はここを真っ先に繋ぐこと。
  Future<void> _writeCacheQuietly(
    String path,
    String body, {
    String? etag,
  }) async {
    try {
      await _cache.write(path, body, etag: etag);
    } on Object {
      // 握り潰す（次回の取得で書き直せる）
    }
  }

  /// 304 の後に取得時刻だけ入れ直す。失敗しても表示には関係しない。
  Future<void> _touchCacheQuietly(String path) async {
    try {
      await _cache.touch(path);
    } on Object {
      // 握り潰す
    }
  }

  /// **必ず配信元に問い合わせてから返す。** 引っ張って更新・アクティブ復帰など、
  /// 「今の配信内容が欲しい」時に使う。
  ///
  /// `watch()` を貼り直すだけでは足りない。あちらは先にキャッシュを流すので、
  /// 呼び出し側が最初の 1 件を待つと**取得の完了を待たずに返ってしまう**
  /// （スピナーが即座に閉じる）。ここで先にキャッシュを温めてから貼り直す。
  ///
  /// **キャッシュは `ETag` を取るために読む。** 変わっていなければ 304 が返り、
  /// その時はキャッシュの本文をそのまま解いて返す（通信は往復するので
  /// 「今の配信内容だ」という保証は変わらない）。
  Future<T> fetchFresh<T>(String path, T Function(String body) decode) async {
    final cached = await _cache.read(path);
    final payload = await _client.fetch(path, etag: cached?.etag);
    if (payload.notModified && cached != null) {
      await _touchCacheQuietly(path);
      return decode(cached.body);
    }
    final value = decode(payload.body);
    await _writeCacheQuietly(path, payload.body, etag: payload.etag);
    return value;
  }

  /// 取り直して、**本文が変わった時だけ true**。
  ///
  /// **貼り直す相手を絞るために要る。** 貼り直すと、ストリームの作り直し・
  /// キャッシュの読み直し・JSON の再デコード（`feed.json` は数千行）・
  /// リストの組み直しが走る。**配信データは大半の復帰で変わっていない**ので、
  /// アクティブ復帰のたびにこれを全 provider ぶん繰り返すのは丸ごと無駄。
  ///
  /// **画面のちらつきを止めるためではない。** riverpod は `invalidate` しても
  /// 直前の値を保つ（`AsyncData(isLoading: true, value: 前の値)`）ので、
  /// 貼り直しても骨組みは出ない —— 復帰のたびに出ていた骨組みは
  /// `home_page.dart` が重ねていた幕のほうで、そちらは撤去した。
  ///
  /// 比べるのは decode 後の値ではなく**本文そのもの**。値の比較は型ごとに
  /// `==` を用意することになり、1 つ実装し忘れると黙って「毎回変わった」に
  /// 倒れる（＝この関数が何も絞らなくなる）。
  Future<bool> fetchFreshIfChanged<T>(
    String path,
    T Function(String body) decode,
  ) async {
    final cached = await _cache.read(path);
    final payload = await _client.fetch(path, etag: cached?.etag);
    // **304 は「変わっていない」そのもの。** 本文を比べるまでもない
    if (payload.notModified && cached != null) {
      await _touchCacheQuietly(path);
      return false;
    }
    // **先に decode する。** 壊れた本文でキャッシュを上書きしない
    decode(payload.body);
    await _writeCacheQuietly(path, payload.body, etag: payload.etag);
    return cached?.body != payload.body;
  }
}

/// JSON 配列を受け取ってモデルのリストにする decode を組み立てる。
///
/// **読めない要素は 1 件ずつ落とす。** 1 件が型に合わないだけで一覧ごと
/// 例外にすると、キャッシュがある時は `CdnRepository.watch` が失敗を握り潰すので
/// **エラーも出ずに古い一覧のまま黙って止まり**、キャッシュが無ければ全件が
/// 消える。
///
/// **web とは逆の倒し方をしている。** web は 1 件でも形が崩れていれば**ビルドごと
/// 止める**（`src/utils/data.ts` の `fetchArticles`。公開中のページを壊れた版で
/// 上書きしないため）。アプリは利用者の端末で動いていて止めようが無いので、
/// 読める記事を出し続けるほうを採る。
///
/// **ただし全件読めなければ例外にする。** 配信の形そのものが変わった時
/// （鍵の改名など）まで「0 件」に潰すと、壊れているのに「記事がありません」と
/// 出る。配列でない本文も同じく例外（形が違う）。
List<T> Function(String) decodeJsonList<T>(
  T Function(Map<String, dynamic>) fromJson,
) => (body) {
  final raw = jsonDecode(body) as List<dynamic>;
  final items = <T>[];
  Object? firstError;
  for (final e in raw) {
    try {
      items.add(fromJson(e as Map<String, dynamic>));
    } on Object catch (error) {
      firstError ??= error;
    }
  }
  if (items.isEmpty && firstError != null) {
    throw FormatException('配信の要素が 1 件も読めない: $firstError');
  }
  return List.unmodifiable(items);
};

/// JSON オブジェクトを受け取ってモデルにする decode を組み立てる。
T Function(String) decodeJsonObject<T>(
  T Function(Map<String, dynamic>) fromJson,
) =>
    (body) => fromJson(jsonDecode(body) as Map<String, dynamic>);

final cdnRepositoryProvider = Provider<CdnRepository>(
  (ref) => CdnRepository(
    client: ref.watch(cdnClientProvider),
    cache: ref.watch(jsonCacheProvider),
  ),
);
