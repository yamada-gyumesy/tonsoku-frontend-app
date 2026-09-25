import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/cdn/cdn_paths.dart';
import 'package:tonsoku/core/cdn/cdn_repository.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// マップの配信（`app/shop.json` / `app/limited.json`）の取得。
///
/// **牛めしレーダーの `DataSyncRepository`（`version.json` を見て 2 つを落とし直す）
/// を写さず、他の配信と同じ `CdnRepository` を通す。** 理由は `CdnPaths.appShops`。
/// キャッシュを先に出してから取り直すので、電波の悪い店先でも前回の店が即座に出る。
///
/// **ロケールを持たない**（`app/` は日本語 1 つ）。
class MapRepository {
  MapRepository({required this._cdn});

  final CdnRepository _cdn;

  Stream<List<Shop>> watchShops() => _cdn.watch(CdnPaths.appShops, _shops);

  Stream<List<LimitedMenu>> watchLimited() =>
      _cdn.watch(CdnPaths.appLimited, _limited);

  /// 取り直して、**どちらかが変わった時だけ true**（アクティブ復帰用）。
  ///
  /// **売り切れは 15 分ごとに変わる**ので、店先で開き直した時に古いまま
  /// 出さないよう復帰のたびに聞く（変わっていなければ 304 で本文は流れない）。
  Future<bool> refreshIfChanged() async {
    final changed = await Future.wait([
      _cdn.fetchFreshIfChanged(CdnPaths.appShops, _shops),
      _cdn.fetchFreshIfChanged(CdnPaths.appLimited, _limited),
    ]);
    return changed.any((c) => c);
  }

  /// **店は 1 軒ずつ落とす**（`decodeJsonList`）。1 軒の形が崩れただけで
  /// 地図から全店が消えるより、残りを出すほうがよい。
  static final _shops = decodeJsonList(Shop.fromJson);

  /// **品は配列が空でも正常**（店舗限定が無い週）。`decodeJsonList` は空配列を
  /// そのまま空で返す（例外にするのは「要素があるのに 1 件も読めない」時だけ）。
  static List<LimitedMenu> _limited(String body) => [
    for (final m in decodeLimitedAll(body))
      if (isShown(m)) m,
  ];

  /// 配信をそのまま読む（絞る前。鍵の対応を確かめるテスト用）。
  static final decodeLimitedAll = decodeJsonList(LimitedMenu.fromJson);

  /// 地図に出す品か。**次の 2 つは出さない**（どちらもユーザーの判断）。
  ///
  /// - **全店で終売した品**（[LimitedMenu.endedAt] が入っている）。配信は
  ///   14 日間残すが、もう買えない品で絞り込んでも行き先が無い。店ごとの終売
  ///   （まだどこかで売っている品の、一部の店の終売）は出す
  /// - **「単品◯◯」**。松のやは同じ品を「◯◯定食」と「単品◯◯」の 2 項目で出し、
  ///   取扱店も同じ（tonsoku-backend-batch の `app/articles/context.py` の
  ///   `_NAME_NOISE`）。両方並べると同じ品のチップが 2 つ並び、店の詳細にも
  ///   同じ品が 2 行出るだけになる
  static bool isShown(LimitedMenu m) =>
      m.endedAt == null && !m.name.startsWith('単品');

  /// テストから本文を読むための口（fixtures を同じ規則で読む）。
  static List<Shop> decodeShops(String body) => _shops(body);
  static List<LimitedMenu> decodeLimited(String body) => _limited(body);
}

final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => MapRepository(cdn: ref.watch(cdnRepositoryProvider)),
);

final shopsProvider = StreamProvider<List<Shop>>(
  (ref) => ref.watch(mapRepositoryProvider).watchShops(),
);

final limitedMenusProvider = StreamProvider<List<LimitedMenu>>(
  (ref) => ref.watch(mapRepositoryProvider).watchLimited(),
);

/// 店ごとの品の索引。**取れない間・失敗した時は空**（店舗限定が無くても
/// 店の地図としては使える。印が普通の店の形になるだけ）。
final limitedIndexProvider = Provider<LimitedIndex>((ref) {
  final menus = ref.watch(limitedMenusProvider).value;
  return menus == null ? LimitedIndex.empty : LimitedIndex(menus);
});
