import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/data/stations.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/domain/shop_state.dart';
import 'package:tonsoku/features/map/presentation/widgets/shop_marker.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 地図に置く店 1 軒ぶん（絞り込みを通したもの）。
class ShopEntry {
  const ShopEntry({
    required this.shop,
    required this.state,
    required this.limited,
    required this.availability,
  });

  final Shop shop;
  final ShopState state;

  /// この店の品と状態（全部。店の詳細に出す）。
  final List<ShopLimited> limited;

  /// 印に出す状態（絞り込みを通した品のうち一番強いもの）。普通の店は null。
  final LimitedAvailability? availability;
}

/// 店の印の層。
///
/// **まとめ（クラスタリング）はしない。** 681 軒は全国に散っていて、引いた
/// 倍率でも小さな点なら分布として読める。まとめると**店舗限定の店が普通の店の
/// 束に飲まれて見えなくなる**（このマップの主役がそれなのに）。代わりに:
///
/// - 引いた倍率（[smallBelow] 未満）では点も印も小さくする
/// - **店舗限定の印を必ず上に重ねる**（並びは呼ぶ側で、普通の店 → 終売 →
///   発売前 → 販売中の順にしてある）
///
/// **ここで `MapCamera.of` を読まないこと。** 読むと地図を動かすたびにこの層が
/// 作り直され、`MarkerLayer` が 681 軒の座標を毎フレーム投影し直す（同じ
/// インスタンスの間は投影を持ち回す作り）。倍率で変わるのは [small] だけなので、
/// 呼ぶ側が段の切り替わりだけを見て渡す。
class ShopsLayer extends StatelessWidget {
  const ShopsLayer({
    required this.entries,
    required this.small,
    required this.onTap,
    super.key,
  });

  final List<ShopEntry> entries;

  /// 引いた倍率（[smallBelow] 未満）か。
  final bool small;
  final ValueChanged<ShopEntry> onTap;

  /// この倍率より引いたら印を小さくする（関東が 1 画面に入るくらい）。
  static const smallBelow = 9.0;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        for (final e in entries)
          Marker(
            key: ValueKey(e.shop.code),
            point: LatLng(e.shop.lat, e.shop.lon),
            width: ShopMarker.hitSize,
            height: ShopMarker.hitSize,
            child: Semantics(
              button: true,
              label: e.shop.name,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(e),
                child: ShopMarker(
                  availability: e.availability,
                  dimmed: !e.state.isOpen,
                  small: small,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 駅の層。**寄った時（[minZoom] 以上）だけ、見えている範囲の駅だけを置く。**
///
/// 8,700 駅を全部 `Marker` にすると、動かすたびに全部を作り直すことになる。
/// 見えている範囲で先に絞ると、z13 で数十駅に収まる。
///
/// **z13 から出す。** 市区町村の名前が主役の z12 以下で駅名まで並べると、
/// 都心では駅名で地図が埋まる（山手線の内側だけで 100 駅を超える）。
class StationsLayer extends StatelessWidget {
  const StationsLayer({
    required this.stations,
    required this.locale,
    super.key,
  });

  final List<Station> stations;
  final AppLocale locale;

  static const minZoom = 13.0;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    if (camera.zoom < minZoom) return const SizedBox.shrink();
    final colors = context.colors;
    final palette = MapPalette.of(colors);
    final bounds = camera.visibleBounds;

    return IgnorePointer(
      child: MarkerLayer(
        markers: [
          for (final s in stations)
            if (bounds.contains(LatLng(s.lat, s.lon)))
              Marker(
                point: LatLng(s.lat, s.lon),
                width: 140,
                height: 16,
                // **点を座標に置き、名前を右へ流す**（中央に置くと名前の真ん中が
                // 駅の位置に見える）。`centerRight` は印の左端を座標に合わせる
                alignment: Alignment.centerRight,
                child: _StationLabel(
                  name: locale == AppLocale.en && s.nameEn.isNotEmpty
                      ? s.nameEn
                      : s.name,
                  palette: palette,
                ),
              ),
        ],
      ),
    );
  }
}

class _StationLabel extends StatelessWidget {
  const _StationLabel({required this.name, required this.palette});

  final String name;
  final MapPalette palette;

  @override
  Widget build(BuildContext context) {
    // 縁取り（地名と同じ。道路や線路の上でも読めるように）
    final halo = [
      for (final o in const [
        Offset(-1, 0),
        Offset(1, 0),
        Offset(0, -1),
        Offset(0, 1),
      ])
        Shadow(color: palette.labelHalo, offset: o, blurRadius: 1),
    ];
    return Row(
      children: [
        // 駅の点（`rail` の色の四角。店の丸と形で分ける）
        Transform.translate(
          offset: const Offset(-3, 0),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: palette.rail,
              border: Border.all(color: palette.labelHalo),
            ),
          ),
        ),
        const SizedBox(width: 1),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.clip,
            softWrap: false,
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              color: palette.label,
              shadows: halo,
            ),
          ),
        ),
      ],
    );
  }
}

/// 現在地の印。**緑の点**（差し色。店の赤・茶と取り違えない）。
class MyLocationMarker extends StatelessWidget {
  const MyLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: colors.green.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surface, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
