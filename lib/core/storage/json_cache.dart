import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// キャッシュから読み出した配信データ。
class CachedPayload {
  const CachedPayload({
    required this.body,
    required this.fetchedAt,
    required this.etag,
  });

  final String body;

  /// 取得した時刻。**取り直しの間隔を決めるのに使う**（`CdnRepository`）。
  final DateTime fetchedAt;

  /// 配信元が返した `ETag`。**次の取得で `If-None-Match` に載せる。**
  ///
  /// 変わっていなければ 304 が返って本文は流れない（実測 0 バイト）。
  /// **記事は後から直されるので取り直しは必ず要る**が、毎回まるごと落とすと
  /// R2 に無駄がかかる。持っていない（古い形のキャッシュ）なら null で、
  /// その時は普通に取り直す。
  final String? etag;
}

/// 配信データ（JSON / Markdown）のローカルキャッシュ。
///
/// **置き場は OS のキャッシュ領域**（iOS の `Library/Caches` 相当）。中身はすべて
/// CDN から取り直せる再生成可能なデータなので、iCloud にバックアップされる
/// Application Support ではなくこちらが正しい。容量逼迫時に OS に消される可能性は
/// あるが、消されても次回の取得で復旧するだけで実害がない。
class JsonCache {
  JsonCache(this._directory);

  final Directory _directory;

  static Future<JsonCache> open() async =>
      JsonCache(await getApplicationCacheDirectory());

  /// 配信パスをそのままファイル名にする。`/` を含むのでパーセントエンコードして
  /// 平坦化する。**単純な置換（`/` → `_`）にしないこと**——`a/b` と `a_b` が
  /// 同じ名前に潰れて、別のデータを取り違える。
  File _fileFor(String key) =>
      File('${_directory.path}/${Uri.encodeComponent(key)}');

  Future<CachedPayload?> read(String key) async {
    final file = _fileFor(key);
    if (!await file.exists()) return null;
    try {
      final envelope = jsonDecode(await file.readAsString());
      if (envelope is! Map<String, dynamic>) return null;
      final body = envelope['body'];
      final fetchedAt = DateTime.tryParse(
        envelope['fetchedAt'] as String? ?? '',
      );
      if (body is! String || fetchedAt == null) return null;
      return CachedPayload(
        body: body,
        fetchedAt: fetchedAt,
        // **無くても読めること。** `etag` を持たない頃に書いたキャッシュが
        // 端末に残っている。null なら条件を付けずに取り直すだけ
        etag: envelope['etag'] as String?,
      );
    } on Object {
      // 壊れたキャッシュは無かったことにする。ここで投げると、一度書き損ねた
      // だけでその画面が永久に開けなくなる
      return null;
    }
  }

  Future<void> write(String key, String body, {String? etag}) async {
    final file = _fileFor(key);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'body': body,
        'fetchedAt': clock.now().toIso8601String(),
        'etag': ?etag,
      }),
    );
  }

  /// **本文はそのままに、取得時刻だけ入れ直す。**
  ///
  /// 条件付き取得で 304（変わっていない）が返った時に使う。ここを更新しないと、
  /// **変わっていないことを確かめた直後なのに「古いキャッシュ」のままになり、
  /// 次の表示でまた問い合わせる。**
  Future<void> touch(String key) async {
    final cached = await read(key);
    if (cached == null) return;
    await write(key, cached.body, etag: cached.etag);
  }

  Future<void> clear() async {
    if (await _directory.exists()) {
      await for (final entity in _directory.list()) {
        if (entity is File) await entity.delete();
      }
    }
  }
}

/// 起動時に一度だけ解決する。`main()` で `overrideWithValue` して差し込む。
final jsonCacheProvider = Provider<JsonCache>(
  (ref) => throw UnimplementedError('jsonCacheProvider must be overridden'),
);
