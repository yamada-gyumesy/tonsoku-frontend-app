import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/lifecycle/app_resume.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/data/bundled_tile_provider.dart';
import 'package:tonsoku/features/map/data/location_repository.dart';
import 'package:tonsoku/features/map/data/map_repository.dart';
import 'package:tonsoku/features/map/data/stations.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';
import 'package:tonsoku/features/map/domain/shop_state.dart';
import 'package:tonsoku/features/map/presentation/map_layers.dart';
import 'package:tonsoku/features/map/presentation/map_theme.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_filter_band.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_legend.dart';
import 'package:tonsoku/features/map/presentation/widgets/shop_sheet.dart';
import 'package:tonsoku/features/shell/presentation/widgets/tonsoku_app_bar.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 同梱の背景地図。**マップを初めて開いた時に読む**（30MB をメモリに置くので、
/// 開かない人には読ませない）。
final bundledTilesProvider = FutureProvider<BundledTileProvider>(
  (ref) => BundledTileProvider.load(rootBundle),
);

/// マップタブ。**店舗限定メニューをどの店で食べられるか**を地図で見せる
/// （とん速固有の面。Issue #8）。
///
/// **機能は牛めしレーダー（`gyumeshi-rader-app`）に倣い、見た目は web に揃える**
/// （ユーザーの指定）。レーダーのレーダー風の画面（暗地・ネオン・同心円）は
/// 持ち込まない。レーダーとの主な違い:
///
/// - **背景地図を持つ**（レーダーは持たない。同梱の Protomaps。`BundledTileProvider`）
/// - **終売（売り切れを含む）を印で分ける**（`ShopMarker`）
/// - **店の情報を増やした**（住所・営業時間・電話・一時閉店・Google マップ。`ShopSheet`）
/// - 絞り込みは**併設**と**店舗限定の品**の 2 種類（`ShopFilter`）
///
/// 並びは上から ロゴのヘッダー → 絞り込みの帯 → 地図。**ヘッダーは退かない**
/// （地図はスクロールしないので、他のタブのように払って隠す動きが無い）。
class MapPage extends ConsumerStatefulWidget {
  const MapPage({required this.onOpenArticle, super.key});

  /// 品の記事を開く（マップのタブの中に積む）。
  final ValueChanged<String> onOpenArticle;

  /// 最初に日本全体を収める範囲（沖縄〜北海道）。**全店がここに入る。**
  static final japan = LatLngBounds(
    const LatLng(24.0, 122.9),
    const LatLng(45.6, 146.0),
  );

  /// 動かせる範囲（同梱の地図の範囲。`tool/build_map.sh` の `BBOX`）。
  /// **中心だけを縛る**（画面の端まで縛ると、引いた倍率で動かせなくなる）。
  static final mapArea = LatLngBounds(
    const LatLng(20.0, 122.0),
    const LatLng(46.0, 154.0),
  );

  static const minZoom = 4.0;

  /// **17 まで寄れる。** 同梱の地図は z11 までで、それより先は引き伸ばして描く
  /// （`BundledTileProvider`）。店の入口がどの通りに面しているかが分かる倍率。
  static const maxZoom = 17.0;

  /// 現在地へ寄せる時の倍率（最寄り駅と周りの店が 1 画面に入る）。
  static const locateZoom = 14.0;

  /// 最後に見ていた位置を残す鍵（`緯度,経度,倍率`）。
  static const cameraKey = 'map_camera';

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final _controller = MapController();
  ShopFilter _filter = const ShopFilter();

  /// 引いた倍率か（[ShopsLayer.smallBelow]）。**段が変わった時だけ作り直す。**
  bool _small = true;

  LatLng? _me;
  bool _locating = false;
  Timer? _saveCamera;

  /// 最後に見ていた位置（開いた時に戻す）。無ければ日本全体。
  late final ({LatLng center, double zoom})? _saved = _readSavedCamera();

  /// 描き方（配色と言語で変わる）。**同じ組の間は作り直さない**（作り直すと
  /// 描いたタイルを全部描き直す）。
  vtr.Theme? _theme;
  (bool, AppLocale)? _themeKey;

  @override
  void initState() {
    super.initState();
    _small = (_saved?.zoom ?? MapPage.minZoom) < ShopsLayer.smallBelow;
    // **開いたらまず現在地へ寄せる**（ユーザーの判断。まだ聞いていなければここで
    // 許可を求める）。取れるまでは最後に見ていた位置（無ければ日本全体）を出しておき、
    // 取れなければそのまま。開いただけで失敗を知らせない（`quiet`）
    WidgetsBinding.instance.addPostFrameCallback((_) => _locate(quiet: true));
  }

  @override
  void dispose() {
    _saveCamera?.cancel();
    _controller.dispose();
    super.dispose();
  }

  ({LatLng center, double zoom})? _readSavedCamera() {
    final raw = ref
        .read(sharedPreferencesProvider)
        .getString(MapPage.cameraKey);
    final parts = raw?.split(',');
    if (parts == null || parts.length != 3) return null;
    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    final zoom = double.tryParse(parts[2]);
    if (lat == null || lon == null || zoom == null) return null;
    return (center: LatLng(lat, lon), zoom: zoom);
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    final small = camera.zoom < ShopsLayer.smallBelow;
    if (small != _small) setState(() => _small = small);
    // **止まってから残す**（動かしている間に毎フレーム書かない）
    _saveCamera?.cancel();
    _saveCamera = Timer(const Duration(milliseconds: 600), () {
      final c = camera.center;
      ref
          .read(sharedPreferencesProvider)
          .setString(
            MapPage.cameraKey,
            '${c.latitude.toStringAsFixed(5)},'
            '${c.longitude.toStringAsFixed(5)},'
            '${camera.zoom.toStringAsFixed(2)}',
          );
    });
  }

  /// 現在地へ寄せる（まだ聞いていなければ許可を求める）。[quiet] なら取れなくても
  /// 知らせない（開いた時）。
  Future<void> _locate({bool quiet = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    final repo = ref.read(locationRepositoryProvider);
    final position = await repo.current();
    if (!mounted) return;
    setState(() => _locating = false);
    if (position == null) {
      if (!quiet) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(ref.read(messagesProvider).mapLocationUnavailable),
          ),
        );
      }
      return;
    }
    final me = LatLng(position.latitude, position.longitude);
    setState(() => _me = me);
    _controller.move(me, MapPage.locateZoom);
  }

  /// アクティブ復帰で取り直す。**売り切れは 15 分ごとに変わる**ので、店先で
  /// 開き直した時に古いまま出さない。変わっていなければ貼り直さない
  /// （`MapRepository.refreshIfChanged`）。
  Future<void> _refresh() async {
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      if (await container.read(mapRepositoryProvider).refreshIfChanged()) {
        container
          ..invalidate(shopsProvider)
          ..invalidate(limitedMenusProvider);
      }
    } on Object {
      // 取れなければ前の値のまま（ホームの復帰と同じ）
    }
  }

  vtr.Theme _themeFor(AppColors colors, AppLocale locale) {
    final key = (colors.isDark, locale);
    if (_theme == null || _themeKey != key) {
      _theme = buildMapTheme(colors, locale);
      _themeKey = key;
    }
    return _theme!;
  }

  void _openShop(ShopEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      // 画面の 3/4 まで（それ以上は中身をスクロールさせる）
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      builder: (sheetContext) => ShopSheet(
        shop: entry.shop,
        state: entry.state,
        limited: entry.limited,
        onOpenArticle: (slug) {
          Navigator.of(sheetContext).pop();
          widget.onOpenArticle(slug);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    listenAppResume(ref, _refresh);

    final colors = context.colors;
    final locale = ref.watch(localeControllerProvider);
    final t = ref.watch(messagesProvider);
    final tiles = ref.watch(bundledTilesProvider).value;
    final stations = ref.watch(stationsProvider).value ?? const [];
    final shops = ref.watch(shopsProvider);
    final index = ref.watch(limitedIndexProvider);
    final menus = ref.watch(limitedMenusProvider).value ?? const [];

    final entries = _entries(shops.value ?? const [], index);
    final present = {for (final e in entries) ?e.availability};

    final saved = _saved;
    final map = FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: saved?.center ?? const LatLng(36.5, 137.5),
        initialZoom: saved?.zoom ?? MapPage.minZoom,
        initialCameraFit: saved == null
            ? CameraFit.bounds(
                bounds: MapPage.japan,
                padding: const EdgeInsets.all(16),
              )
            : null,
        minZoom: MapPage.minZoom,
        maxZoom: MapPage.maxZoom,
        // タイルが描けるまでの地は海の色（灰色の四角を出さない）
        backgroundColor: MapPalette.of(colors).water,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: MapPage.mapArea,
        ),
        // **回転させない**（北が上のまま。2 本指の操作で意図せず回ると戻し方が
        // 分からない。レーダーのコンパスのような戻す手段も持たない）
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onPositionChanged: _onPositionChanged,
      ),
      children: [
        if (tiles != null)
          VectorTileLayer(
            theme: _themeFor(colors, locale),
            tileProviders: TileProviders({mapTileSource: tiles}),
            // **描いたタイル（画像）の置き場は 20MB まで。** タイルの元は同梱なので
            // 置かなくても描けるが、描き直しは重い（地名の配置まで毎回やる）。
            // 既定の 50MB は、アプリ本体に 30MB の地図を持つうえでは大きすぎる。
            // 置き場は OS の一時領域（`getTemporaryDirectory`）で、端末の容量が
            // 足りなければ OS が消してよい
            fileCacheMaximumSizeInBytes: 20 * 1024 * 1024,
            maximumZoom: MapPage.maxZoom,
          ),
        StationsLayer(stations: stations, locale: locale),
        ShopsLayer(entries: entries, small: _small, onTap: _openShop),
        if (_me case final me?)
          MarkerLayer(
            markers: [
              Marker(
                point: me,
                width: 30,
                height: 30,
                child: const IgnorePointer(child: MyLocationMarker()),
              ),
            ],
          ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.page,
      body: Column(
        children: [
          const TonsokuAppBar(hidden: 0),
          MapFilterBand(
            filter: _filter,
            menus: menus,
            shownCount: shops.hasValue ? entries.length : null,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: map),
                // 店を取れなかった（キャッシュも無い初回）。地図は見せたまま
                // 上に重ねる
                if (shops.hasError && !shops.hasValue)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: _LoadFailed(
                      message: t.commonError,
                      retry: t.commonRetry,
                      onRetry: () => ref.invalidate(shopsProvider),
                    ),
                  ),
                Positioned(
                  left: 8,
                  right: 72,
                  bottom: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── 動画広告（リワード。#5）─────────────────────
                      // **視聴のボタンはここ（凡例の上）に置く**予定。視聴と報酬の
                      // 対応を画面に明示する（Issue #8 のユーザーの指定）。広告の
                      // SDK は #5 で入れるので、ここには何も置かない
                      MapLegend(present: present),
                      const SizedBox(height: 4),
                      const MapAttribution(),
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _LocateButton(
                    label: t.mapMyLocation,
                    busy: _locating,
                    onTap: _locate,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 地図に置く店を並べる。**時刻で変わる判定（店の状態・品の発売前）は
  /// ここで毎回求める**（provider に持たせない。`shopStateOf` の注記）。
  List<ShopEntry> _entries(List<Shop> shops, LimitedIndex index) {
    final now = clock.now();
    final entries = <ShopEntry>[];
    for (final shop in shops) {
      final limited = index.at(shop.code, now: now);
      if (!_filter.matches(shop, limited)) continue;
      entries.add(
        ShopEntry(
          shop: shop,
          state: shopStateOf(shop, now: now),
          limited: limited,
          availability: strongest(_filter.relevant(limited)),
        ),
      );
    }
    // **強い印ほど後ろ（＝上に重なる）。** 普通の店 → 終売 → 発売前 →
    // 販売中
    int rank(ShopEntry e) => switch (e.availability) {
      null => 0,
      final a => LimitedAvailability.values.length - a.index,
    };
    entries.sort((a, b) => rank(a).compareTo(rank(b)));
    return entries;
  }
}

class _LocateButton extends StatelessWidget {
  const _LocateButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colors.surface,
        shape: CircleBorder(side: BorderSide(color: colors.border)),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.my_location, size: 22, color: colors.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({
    required this.message,
    required this.retry,
    required this.onRetry,
  });

  final String message;
  final String retry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 13, color: colors.text),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(retry)),
          ],
        ),
      ),
    );
  }
}
