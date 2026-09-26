import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/cdn/cdn_paths.dart';
import 'package:tonsoku/core/cdn/cdn_repository.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/network/cdn_client.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// マップの配信（`app/shop.json` / `app/limited.json`）の取得。
///
/// **牛めしレーダーの `DataSyncRepository`（`version.json` を見て 2 つを落とし直す）
/// を写さず、他の配信と同じ `CdnRepository` を通す。** 理由は `CdnPaths.appShops`。
/// キャッシュを先に出してから取り直すので、電波の悪い店先でも前回の店が即座に出る。
///
/// **表示言語の面を読む**（英語・中国語は `i18n/{locale}/app/…`。`CdnPaths.appShops`）。
/// キャッシュの鍵はパスなので、言語ごとに分かれる。言語を切り替えると
/// [mapRepositoryProvider] が作り直され、店も品も読み直される。
///
/// ## 英語・中国語の面が無い（404）時
///
/// **日本語の面へ落とさず、店も品も 0 件として流す。** ロケール別の面は
/// tonsoku-backend-batch#286 から出るもので、反映前の CDN には無い（2026-09-26 実測で
/// `i18n/{en,zh}/app/shop.json` は 404）。
///
/// - **日本語へ落とすと、英語・中国語の画面に日本語の店名・住所・品名が出る**
///   （出さないのがユーザーの決定。Issue #35）
/// - **失敗（再試行つきの「読み込めませんでした」）にもしない。** 配信が出るまで
///   押しても永久に成功しない再試行が並ぶだけになる（`CouponRepository.watch` と同じ判断）。
///   地図・駅・現在地はそのまま使える
///
/// **日本語の面の 404 は今までどおり失敗として上げる**（`app/` は必ずある面で、
/// 404 は配信の異常。`CdnNotFoundException`）。
class MapRepository {
  MapRepository({required this._cdn, required AppLocale locale})
    : _locale = locale,
      _paths = CdnPaths(locale);

  final CdnRepository _cdn;
  final AppLocale _locale;
  final CdnPaths _paths;

  Stream<List<Shop>> watchShops() => _orEmpty(_paths.appShops, _shops);

  /// 地図に出す品（[isShown]）。[singles] は英語・中国語の面の「単品◯◯」の ID
  /// （[watchSingleMenuIds]）。
  Stream<List<LimitedMenu>> watchLimited({Set<String> singles = const {}}) =>
      _orEmpty(
        _paths.appLimited,
        (body) => decodeLimited(body, singles: singles),
      );

  /// **英語・中国語の面で「単品◯◯」を見分けるための ID。** 日本語の面では空
  /// （品名で見分けられる。[isShown]）。
  ///
  /// 訳された品名からは「単品」を見分けられない（英語は `… only` と訳す規則だが、
  /// 公式訳が付く品は形が決まらず、中国語は規則も無い。tonsoku-backend-batch の
  /// `docs/i18n/translation-rules.md`）。**`campaign_id` は言語で変わらない**ので、
  /// 日本語の面（数 KB）で見分けて ID で落とす。
  ///
  /// 日本語の面が取れない時は空（品が 2 つずつ並ぶだけで、地図は使える）。
  /// **失敗をここで空に変えて、流れに失敗を出さない。** 失敗を流すと Riverpod 3 が
  /// provider を既定で再試行し、その間 `singleMenuIdsProvider.future` が待ち続けて
  /// 品が数十秒出ない（`limitedMenusProvider` の catch には届かない）。
  Stream<Set<String>> watchSingleMenuIds() async* {
    if (_locale.isDefault) {
      yield const <String>{};
      return;
    }
    try {
      await for (final ids in _cdn.watch(
        const CdnPaths(AppLocale.ja).appLimited,
        _singleIds,
      )) {
        yield ids;
      }
    } on Object {
      yield const <String>{};
    }
  }

  /// 取り直して、**どちらかが変わった時だけ true**（アクティブ復帰用）。
  ///
  /// **売り切れは 15 分ごとに変わる**ので、店先で開き直した時に古いまま
  /// 出さないよう復帰のたびに聞く（変わっていなければ 304 で本文は流れない）。
  /// 英語・中国語の面がまだ無い（404）時は「変わっていない」。
  Future<bool> refreshIfChanged() async {
    final changed = await Future.wait([
      _changed(_paths.appShops, _shops),
      _changed(_paths.appLimited, decodeLimitedAll),
      // 「単品◯◯」の見分け（[watchSingleMenuIds]）。新しい品が出た週に要る
      if (!_locale.isDefault)
        _changed(const CdnPaths(AppLocale.ja).appLimited, _singleIds),
    ]);
    return changed.any((c) => c);
  }

  Future<bool> _changed<T>(String path, T Function(String) decode) async {
    try {
      return await _cdn.fetchFreshIfChanged(path, decode);
    } on CdnNotFoundException {
      if (_locale.isDefault) rethrow;
      return false;
    }
  }

  /// [MapRepository] の doc の「英語・中国語の面が無い（404）時」。
  ///
  /// **`yield*` を使わないこと**（`CouponRepository.watch` の doc。委譲はエラーを
  /// その場で throw せず転送するので、`on CdnNotFoundException` を素通りする）。
  Stream<List<T>> _orEmpty<T>(
    String path,
    List<T> Function(String body) decode,
  ) async* {
    try {
      await for (final value in _cdn.watch(path, decode)) {
        yield value;
      }
    } on CdnNotFoundException {
      if (_locale.isDefault) rethrow;
      yield <T>[];
    }
  }

  /// **店は 1 軒ずつ落とす**（`decodeJsonList`）。1 軒の形が崩れただけで
  /// 地図から全店が消えるより、残りを出すほうがよい。
  static final _shops = decodeJsonList(Shop.fromJson);

  /// **品は配列が空でも正常**（店舗限定が無い週）。`decodeJsonList` は空配列を
  /// そのまま空で返す（例外にするのは「要素があるのに 1 件も読めない」時だけ）。
  static List<LimitedMenu> decodeLimited(
    String body, {
    Set<String> singles = const {},
  }) => [
    for (final m in decodeLimitedAll(body))
      if (isShown(m, singles: singles)) m,
  ];

  /// 配信をそのまま読む（絞る前。鍵の対応を確かめるテスト用）。
  static final decodeLimitedAll = decodeJsonList(LimitedMenu.fromJson);

  static Set<String> _singleIds(String body) => {
    for (final m in decodeLimitedAll(body))
      if (m.name?.startsWith(_single) ?? false) m.campaignId,
  };

  static const _single = '単品';

  /// 地図に出す品か。**次の 3 つは出さない**。
  ///
  /// - **全店で終売した品**（[LimitedMenu.endedAt] が入っている）。配信は
  ///   14 日間残すが、もう買えない品で絞り込んでも行き先が無い。店ごとの終売
  ///   （まだどこかで売っている品の、一部の店の終売）は出す（ユーザーの判断）
  /// - **「単品◯◯」**。松のやは同じ品を「◯◯定食」と「単品◯◯」の 2 項目で出し、
  ///   取扱店も同じ（tonsoku-backend-batch の `app/articles/context.py` の
  ///   `_NAME_NOISE`）。両方並べると同じ品のチップが 2 つ並び、店の詳細にも
  ///   同じ品が 2 行出るだけになる（ユーザーの判断）。英語・中国語の面では
  ///   品名で見分けられないので [singles] の ID で落とす（[watchSingleMenuIds]）
  /// - **品名が null の品**（英語・中国語で訳がまだ無い。日本語に落とさない）。
  ///   品はチップ・店の詳細の行・画面外の吹き出しの**名前で選ぶもの**で、
  ///   名前の無いチップは何を絞るのか読めない。印の形だけに効かせると、
  ///   店を開いても理由の書かれていない印になる。訳が付けば次の配信で出る
  static bool isShown(LimitedMenu m, {Set<String> singles = const {}}) {
    final name = m.name;
    return m.endedAt == null &&
        name != null &&
        !name.startsWith(_single) &&
        !singles.contains(m.campaignId);
  }

  /// テストから本文を読むための口（fixtures を同じ規則で読む）。
  static List<Shop> decodeShops(String body) => _shops(body);
}

final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => MapRepository(
    cdn: ref.watch(cdnRepositoryProvider),
    locale: ref.watch(localeControllerProvider),
  ),
);

final shopsProvider = StreamProvider<List<Shop>>(
  (ref) => ref.watch(mapRepositoryProvider).watchShops(),
);

/// 英語・中国語の面の「単品◯◯」の ID（`MapRepository.watchSingleMenuIds`）。
final singleMenuIdsProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(mapRepositoryProvider).watchSingleMenuIds(),
);

final limitedMenusProvider = StreamProvider<List<LimitedMenu>>((ref) async* {
  final repository = ref.watch(mapRepositoryProvider);
  // **見分けられなくても品は出す**（2 つずつ並ぶだけ。品ごと消すより良い）
  Set<String> singles;
  try {
    singles = await ref.watch(singleMenuIdsProvider.future);
  } on Object {
    singles = const {};
  }
  await for (final menus in repository.watchLimited(singles: singles)) {
    yield menus;
  }
});

/// 店ごとの品の索引。**取れない間・失敗した時は空**（店舗限定が無くても
/// 店の地図としては使える。印が普通の店の形になるだけ）。
final limitedIndexProvider = Provider<LimitedIndex>((ref) {
  final menus = ref.watch(limitedMenusProvider).value;
  return menus == null ? LimitedIndex.empty : LimitedIndex(menus);
});
