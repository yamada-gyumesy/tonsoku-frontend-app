import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/map/data/bundled_tile_provider.dart';
import 'package:tonsoku/features/map/data/compass_repository.dart';
import 'package:tonsoku/features/map/data/location_repository.dart';
import 'package:tonsoku/features/map/data/map_repository.dart';
import 'package:tonsoku/features/map/data/stations.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/domain/next_change.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';
import 'package:tonsoku/features/map/domain/shop_state.dart';
import 'package:tonsoku/features/map/presentation/map_layers.dart';
import 'package:tonsoku/features/map/presentation/map_theme.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_filter_band.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_scale_bar.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_search.dart';
import 'package:tonsoku/features/map/presentation/widgets/offscreen_counts.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/features/map/presentation/widgets/map_attribution.dart';
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
/// - **売り切れ・終売を印で分ける**（`ShopMarker`）
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

  /// **進行方向が上**（コンパスのボタン。牛めしレーダーの「N 固定 ⇄ コンパス」を
  /// 写した）。既定は北が上。
  bool _headingUp = false;

  /// 進行方向が上の間、端末の向きに地図の回転を合わせ続けるか。**地図を指で
  /// 動かしたら外す**（回転はその時の角度のまま。Google マップと同じ）。
  /// 現在地のボタンで戻る。
  bool _follow = false;
  StreamSubscription<double>? _compass;

  /// 端末の向き（度）。現在地の印の扇に使う。**取れるまでは null**。
  double? _heading;

  /// 松のや専門店・併設の段を開いているか（検索バーの右のフィルタのボタン）。
  bool _brandsOpen = false;

  /// 地図の回転（度。ボタンの矢印を北へ向けるのに使う）。
  double _rotation = 0;

  /// 時刻だけで印が変わる瞬間（発売・閉店・再開）に組み直す（[_scheduleTick]）。
  Timer? _tick;
  DateTime? _tickAt;

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
    _tick?.cancel();
    unawaited(_compass?.cancel());
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
    // 指で動かしたら向きの追従を外す（回転は今の角度のまま）
    if (hasGesture && _follow) _follow = false;
    if ((camera.rotation - _rotation).abs() > 0.5) {
      setState(() => _rotation = camera.rotation);
    }
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

  /// 地図の向きを切り替える（北が上 ⇄ 進行方向が上）。
  ///
  /// 進行方向が上にした時は**現在地へ寄せてから**回す（牛めしレーダーと同じ。
  /// 別の場所を見たまま回すと、どこを中心に回っているのか分からない）。
  /// 北が上に戻す時は回転を 0 に戻す（方位は現在地の扇のために聞き続ける）。
  void _toggleHeading() {
    if (_headingUp) {
      setState(() {
        _headingUp = false;
        _follow = false;
      });
      _controller.rotate(0);
      return;
    }
    setState(() {
      _headingUp = true;
      _follow = true;
    });
    _listenCompass();
    unawaited(_locate());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // **マップのタブが見えていない間は方位のセンサーを止める**（下タブは
    // indexedStack で、裏のタブもこの画面は生きたまま。止めないと別のタブに
    // いる間も Android は約 50Hz でセンサーと setState が回り続ける）。
    // 裏のタブは go_router が TickerMode を切るので、それを合図にする
    _tabActive = TickerMode.valuesOf(context).enabled;
    if (!_tabActive) {
      _stopCompass();
    } else if (_me != null || _headingUp) {
      _listenCompass();
    }
  }

  bool _tabActive = true;

  void _stopCompass() {
    unawaited(_compass?.cancel());
    _compass = null;
  }

  /// 方位のセンサーを聞き始める（既に聞いていれば何もしない）。**現在地が
  /// 分かってから**聞く（現在地の扇と、進行方向が上のモードに使う）。
  /// 聞いている間だけセンサーが動く（`CompassRepository`）。
  void _listenCompass() {
    if (_compass != null || !_tabActive) return;
    _compass = ref.read(compassRepositoryProvider).headingStream().listen(
      (heading) {
        if (!mounted) return;
        if (_follow) _controller.rotate(-heading);
        // 扇は 1 度以上変わった時だけ描き直す（センサーは細かく揺れる）
        final prev = _heading;
        if (prev == null || _angleDiff(prev, heading) >= 1) {
          setState(() => _heading = heading);
        }
      },
      // 方位を出せない端末（センサーが無い・シミュレータ）では扇を出さず、
      // 北が上のまま
      onError: (_) {},
    );
  }

  static double _angleDiff(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
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
    // **日本の外にいる時は寄せない。** 地図は日本の範囲しか持たず、中心は
    // [MapPage.mapArea] に縛ってあるので、寄せると範囲の端に張り付いた
    // 何も無い画面になる（海外から開いた人・既定の位置が米国のシミュレータ）
    if (!MapPage.mapArea.contains(me)) {
      if (!quiet) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(ref.read(messagesProvider).mapLocationUnavailable),
          ),
        );
      }
      return;
    }
    setState(() {
      _me = me;
      // 進行方向が上の間は、現在地へ戻ったら向きの追従も戻す
      if (_headingUp) _follow = true;
    });
    _listenCompass();
    _controller.move(me, MapPage.locateZoom);
  }

  /// アクティブ復帰で取り直す。**売り切れは 15 分ごとに変わる**ので、店先で
  /// 開き直した時に古いまま出さない。配信が変わっていなければ貼り直さない
  /// （`MapRepository.refreshIfChanged`）が、**画面は必ず組み直す** ―― 発売前 →
  /// 販売中のように時刻だけで変わる印は、裏にいた間の時刻を拾えていない
  /// （裏ではタイマーも止まる）。
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
    if (mounted) setState(() {});
  }

  /// 次に時刻だけで印が変わる瞬間（[nextChangeAfter]）に組み直すよう仕掛ける。
  /// 同じ瞬間を既に待っていれば仕掛け直さない（build のたびに呼ぶため）。
  void _scheduleTick(DateTime? at) {
    if (at == _tickAt) return;
    _tick?.cancel();
    _tickAt = at;
    if (at == null) return;
    // 境目ちょうどに組むと判定が前の側に落ちうるので、少しだけ後にする
    final wait = at.difference(clock.now()) + const Duration(seconds: 1);
    _tick = Timer(wait.isNegative ? Duration.zero : wait, () {
      _tickAt = null;
      if (mounted) setState(() {});
    });
  }

  vtr.Theme _themeFor(
    AppColors colors,
    AppLocale locale,
    BundledTileProvider tiles,
  ) {
    final key = (colors.isDark, locale);
    if (_theme == null || _themeKey != key) {
      _theme = buildMapTheme(colors, locale, dataVersion: tiles.dataVersion);
      _themeKey = key;
    }
    return _theme!;
  }

  void _openShop(Shop shop) {
    // **開く時点の時刻で求め直す**（印は最後に組んだ時のもの。
    // 印の組み直しを待たずに、押した時の状態を出す）
    final now = clock.now();
    final state = shopStateOf(shop, now: now);
    final limited = ref.read(limitedIndexProvider).at(shop.code, now: now);
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
        shop: shop,
        state: state,
        limited: limited,
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
    final menusValue = ref.watch(limitedMenusProvider).value;
    final menus = menusValue ?? const <LimitedMenu>[];
    // 配信から消えた品の選択を外す（`ShopFilter.retainMenus`）。取れる前は触らない。
    // 同じ build の中で使うだけなので setState は要らない
    if (menusValue != null) {
      _filter = _filter.retainMenus({for (final m in menusValue) m.campaignId});
    }

    final entries = _entries(shops.value ?? const [], index);
    _scheduleTick(nextChangeAfter(clock.now(), shops.value ?? const [], menus));

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
            theme: _themeFor(colors, locale, tiles),
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
        ShopsLayer(
          entries: entries,
          small: _small,
          onTap: (e) => _openShop(e.shop),
        ),
        if (_me case final me?)
          MarkerLayer(
            markers: [
              Marker(
                point: me,
                width: MyLocationMarker.size,
                height: MyLocationMarker.size,
                child: IgnorePointer(
                  child: MyLocationMarker(heading: _heading),
                ),
              ),
            ],
          ),
        // **縮尺は下の真ん中、著作権表記は左下**（ユーザーの指定）。縮尺は地図の
        // 位置と倍率を読む（`MapCamera.of`）ので地図の層として置く。**凡例は置かない**（ユーザーの指定。印の意味は品のチップの
        // 内訳が兼ねる。`MenuChip`）
        // ── 動画広告（リワード。#5）─────────────────────
        // **視聴のボタンは左下に置く**予定。視聴と報酬の対応を画面に明示する
        // （Issue #8 のユーザーの指定）。広告の SDK は #5 で入れるので、ここには
        // 何も置かない
        // 左下の著作権表記と一緒に置く（[_BottomDelegate]。著作権表記の実際の
        // 幅を見て、縮尺をそれに重ならない範囲の真ん中に収める）
        CustomMultiChildLayout(
          delegate: _BottomDelegate(),
          children: [
            LayoutId(
              id: _BottomDelegate.attribution,
              child: const MapAttribution(),
            ),
            LayoutId(id: _BottomDelegate.scale, child: const MapScaleBar()),
          ],
        ),
        // 画面の外の**店舗限定の店**の数（方角ごと。普通の店は数えない ――
        // ユーザーの指定。このマップの主役は店舗限定の店）。**縁の余白は
        // 検索・品・ボタンを避ける**: 下は縮尺・コンパス・現在地・著作権表記
        // （〜140）、左右は札の半分の幅（〜44）
        OffscreenCounts(
          points: [
            for (final e in entries)
              if (e.availability case final a?)
                OffscreenPoint(LatLng(e.shop.lat, e.shop.lon), a),
          ],
          // 上は左上の検索と絞り込みの列の下（品の数と「含める」で高さが変わる。
          // 目安の高さ: 検索 44・併設 40（開いた時だけ）・品 1 つ 52・「含める」42）
          padding: EdgeInsets.fromLTRB(
            44,
            12 +
                44 +
                8 +
                (_brandsOpen ? 40 : 0) +
                menus.length * 52 +
                (_filter.menuIds.isEmpty ? 0 : 42) +
                16,
            44,
            140,
          ),
          onTap: (p) {
            _follow = false;
            _controller.move(p, _controller.camera.zoom);
          },
        ),
      ],
    );

    return Scaffold(
      backgroundColor: colors.page,
      body: Column(
        children: [
          const TonsokuAppBar(hidden: 0),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: map),
                // **並び（ユーザーの指定）**: 上に横いっぱいの検索（店の数はバーの
                // 右端）と絞り込み、右下に上からコンパス・現在地、左下に著作権
                // 表記、下の真ん中に縮尺（地図の層。`FlutterMap` の子）
                // 右下に上からコンパス・現在地（ユーザーの指定）
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // コンパスは現在地の上（ユーザーの指定）
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _CompassButton(
                          label: _headingUp ? t.mapHeadingUp : t.mapNorthUp,
                          headingUp: _headingUp,
                          rotation: _rotation,
                          onTap: _toggleHeading,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _LocateButton(
                          label: t.mapMyLocation,
                          busy: _locating,
                          onTap: _locate,
                        ),
                      ),
                    ],
                  ),
                ),
                // 店を取れなかった（キャッシュも無い初回）。地図は見せたまま、
                // 検索の下に重ねる
                if (shops.hasError && !shops.hasValue)
                  Positioned(
                    top: 64,
                    left: 12,
                    right: 12,
                    child: _LoadFailed(
                      message: t.commonError,
                      retry: t.commonRetry,
                      onRetry: () => ref.invalidate(shopsProvider),
                    ),
                  ),
                // 検索は最後に重ねる（候補の一覧が他の部品より上に出るように）
                Positioned(
                  top: 12,
                  left: 12,
                  // 横いっぱい（ユーザーの指定。コンパスは右下へ移した）
                  right: 12,
                  child: MapSearch(
                    // 探すのは地図に出している店（牛めしレーダーと同じ）
                    shops: [for (final e in entries) e.shop],
                    resetKey: _filter,
                    count: shops.hasValue ? entries.length : null,
                    filter: MapFilterButton(
                      open: _brandsOpen,
                      active: _filter.standalone || _filter.brands.isNotEmpty,
                      onTap: () => setState(() => _brandsOpen = !_brandsOpen),
                    ),
                    onShop: (shop) {
                      _follow = false;
                      _controller.move(
                        LatLng(shop.lat, shop.lon),
                        math.max(_controller.camera.zoom, MapPage.locateZoom),
                      );
                      _openShop(shop);
                    },
                    below: MapFilters(
                      filter: _filter,
                      showBrands: _brandsOpen,
                      menus: menus,
                      onChanged: (f) => setState(() => _filter = f),
                    ),
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
    // **強い印ほど後ろ（＝上に重なる）。** 普通の店 → 終売 → 売り切れ →
    // 発売前 → 販売中
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
        color: MapPalette.of(colors).panel,
        shape: CircleBorder(
          side: BorderSide(color: MapPalette.of(colors).panelBorder),
        ),
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

/// 地図の向きのボタン（牛めしレーダーのコンパスのボタンを、とん速の丸いボタンの
/// 形にしたもの）。見た目は一般的な地図アプリに揃える（ユーザーの指定）:
///
/// - 北が上 … 薄い針の上に大きな「N」
/// - 進行方向が上 … ボタン全体が針（北が赤、南が副テキスト）。北を指して回る
class _CompassButton extends StatelessWidget {
  const _CompassButton({
    required this.label,
    required this.headingUp,
    required this.rotation,
    required this.onTap,
  });

  final String label;
  final bool headingUp;

  /// 地図の回転（度）。北は画面上でこの角度の向きに来る。
  final double rotation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: MapPalette.of(colors).panel,
        shape: CircleBorder(
          side: BorderSide(color: MapPalette.of(colors).panelBorder),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            // **一般的な地図の形**（ユーザーの指定。Google マップと同じ）:
            // - 北が上 … 薄い針の上に大きな「N」（ユーザーの指定）
            // - 進行方向が上 … ボタン全体を針にして、北を指して回す
            child: ExcludeSemantics(
              child: headingUp
                  ? Center(
                      child: Transform.rotate(
                        angle: rotation * math.pi / 180,
                        child: CustomPaint(
                          size: const Size(14, 32),
                          painter: _NeedlePainter(
                            north: colors.primaryText,
                            south: colors.textSub,
                          ),
                        ),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(12, 30),
                          painter: _NeedlePainter(
                            north: colors.primaryText.withValues(alpha: 0.25),
                            south: colors.textSub.withValues(alpha: 0.2),
                          ),
                        ),
                        Text(
                          'N',
                          style: TextStyle(
                            fontSize: 18,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: colors.text,
                            fontFamily: AppTheme.defaultFontFamily,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// コンパスの針（上半分が北、下半分が南の菱形）。
class _NeedlePainter extends CustomPainter {
  const _NeedlePainter({required this.north, required this.south});

  final Color north;
  final Color south;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    canvas
      ..drawPath(
        ui.Path()
          ..moveTo(c.dx, 0)
          ..lineTo(w, c.dy)
          ..lineTo(0, c.dy)
          ..close(),
        Paint()..color = north,
      )
      ..drawPath(
        ui.Path()
          ..moveTo(c.dx, h)
          ..lineTo(w, c.dy)
          ..lineTo(0, c.dy)
          ..close(),
        Paint()..color = south,
      );
  }

  @override
  bool shouldRepaint(_NeedlePainter old) =>
      old.north != north || old.south != south;
}

/// 左下の著作権表記と、下の真ん中の縮尺の置き場。
///
/// **縮尺は画面の真ん中に置き、左右を著作権表記の幅ぶん空けた範囲に収める**
/// （範囲が狭ければ縮尺が棒を縮める。`MapScaleBar`）。左右を同じだけ空けるので
/// 真ん中は保たれ、右下のボタンにもかからない。
class _BottomDelegate extends MultiChildLayoutDelegate {
  static const attribution = 'attribution';
  static const scale = 'scale';

  /// 端からの余白。
  static const inset = 8.0;

  /// 著作権表記との間。
  static const gap = 8.0;

  @override
  void performLayout(Size size) {
    final a = layoutChild(attribution, BoxConstraints.loose(size));
    positionChild(attribution, Offset(inset, size.height - inset - a.height));
    final side = inset + a.width + gap;
    final sc = layoutChild(
      scale,
      BoxConstraints.loose(
        Size(math.max(0, size.width - side * 2), size.height),
      ),
    );
    positionChild(
      scale,
      Offset((size.width - sc.width) / 2, size.height - inset - sc.height),
    );
  }

  @override
  bool shouldRelayout(_BottomDelegate old) => false;
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
      color: MapPalette.of(colors).panel,
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
