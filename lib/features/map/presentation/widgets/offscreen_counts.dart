import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/presentation/widgets/shop_marker.dart';

/// 画面の外にある店の数を、**方角ごとにまとめて画面の縁に出す**（不動産の地図
/// ―― SUUMO など ―― でよくある表記。ユーザーの指定）。見た目は「その方角にある
/// 印（★・☆・×）＋ 合計の数」の吹き出しで、尻尾が店のある方角を指す（[_Badge]）。
///
/// - 数えるのは呼ぶ側が渡した店。マップは**店舗限定の印がある店だけ**を渡す
///   （ユーザーの指定。絞っていれば絞った店のうちの店舗限定の店）
/// - 方角は画面の中心から見た向きで **8 つ**（上・右上・右 …）にまとめる。
///   地図を回している時も**画面の上下左右**で分ける（吹き出しの尻尾が指す向きと、
///   実際に店がある向きを一致させる）
/// - 札を押すと、**その方角で一番近い店**へ寄せる（倍率はそのまま）
///
/// **FlutterMap の子として置く**（`MapCamera.of` で地図が動くたびに組み直す）。
/// 回転する層（`MobileLayerTransformer`）には入れないので、札は回らない。
class OffscreenCounts extends StatelessWidget {
  const OffscreenCounts({
    required this.points,
    required this.onTap,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// 数える店（位置と印の状態。マップは店舗限定の印がある店だけ）。
  final List<OffscreenPoint> points;

  /// 札を押した時（その方角で一番近い店の位置）。
  final ValueChanged<LatLng> onTap;

  /// 札を置かない縁の余白（検索・ボタン・縮尺と重ねない）。
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final size = camera.nonRotatedSize;
    final groups = groupOffscreen(
      points,
      size: size,
      toScreen: camera.latLngToScreenOffset,
    );
    if (groups.isEmpty) return const SizedBox.shrink();

    final area = padding.deflateRect(Offset.zero & size);
    return Stack(
      children: [
        for (final g in groups)
          _Placed(
            anchor: edgePoint(area, g.sector),
            child: _Badge(
              sector: g.sector,
              count: g.count,
              kinds: g.kinds,
              onTap: () => onTap(g.nearest),
            ),
          ),
      ],
    );
  }
}

/// 数える店 1 軒（位置と、印の状態）。
class OffscreenPoint {
  const OffscreenPoint(this.at, this.kind);

  final LatLng at;
  final LimitedAvailability kind;
}

/// 1 つの方角にまとめた画面外の店。
class OffscreenGroup {
  const OffscreenGroup({
    required this.sector,
    required this.count,
    required this.nearest,
    this.kinds = const {},
  });

  /// 方角（0 = 上、時計回りに 45 度ずつ。0〜7）。
  final int sector;
  final int count;

  /// この方角で画面の中心に一番近い店。
  final LatLng nearest;

  /// この方角にある印の状態（吹き出しに並べる。数は [count] の合計だけ）。
  final Set<LimitedAvailability> kinds;
}

/// 画面の外にある店を方角ごとにまとめる（[OffscreenCounts]）。**画面の中の店は
/// 数えない。** [toScreen] は緯度経度を画面の座標にするもの（地図の回転込み）。
List<OffscreenGroup> groupOffscreen(
  List<OffscreenPoint> points, {
  required Size size,
  required Offset Function(LatLng) toScreen,
}) {
  final screen = Offset.zero & size;
  final center = screen.center;
  final counts = List<int>.filled(8, 0);
  final nearest = List<LatLng?>.filled(8, null);
  final nearestDist = List<double>.filled(8, double.infinity);
  final kinds = List.generate(8, (_) => <LimitedAvailability>{});
  for (final point in points) {
    final p = point.at;
    final o = toScreen(p);
    if (screen.contains(o)) continue;
    final d = o - center;
    final s = sectorOf(d);
    counts[s]++;
    kinds[s].add(point.kind);
    final dist = d.distanceSquared;
    if (dist < nearestDist[s]) {
      nearestDist[s] = dist;
      nearest[s] = p;
    }
  }
  return [
    for (var s = 0; s < 8; s++)
      if (counts[s] > 0)
        OffscreenGroup(
          sector: s,
          count: counts[s],
          nearest: nearest[s]!,
          kinds: kinds[s],
        ),
  ];
}

/// 画面の中心からの向き [d] を 8 方角（0 = 上、時計回り）にする。
int sectorOf(Offset d) {
  // 上を 0 にして時計回り（画面の y は下向き）
  final angle = math.atan2(d.dx, -d.dy);
  final turns = (angle / (2 * math.pi) * 8).round();
  return turns % 8;
}

/// [area] の縁で、中心から方角 [sector] へ伸ばした線が当たる点（斜めは角）。
Offset edgePoint(Rect area, int sector) {
  final angle = sector * math.pi / 4;
  final dir = Offset(math.sin(angle), -math.cos(angle));
  final c = area.center;
  final halfW = area.width / 2;
  final halfH = area.height / 2;
  final tx = dir.dx.abs() < 1e-9 ? double.infinity : halfW / dir.dx.abs();
  final ty = dir.dy.abs() < 1e-9 ? double.infinity : halfH / dir.dy.abs();
  final t = math.min(tx, ty);
  // **斜めの方角は領域の角に置く**（ユーザーの指摘。45 度の線は縦長の画面では
  // 角ではなく辺に当たり、辺の途中に斜めの吹き出しが出て落ち着かない）
  if (sector.isOdd) {
    return Offset(
      dir.dx > 0 ? area.right : area.left,
      dir.dy > 0 ? area.bottom : area.top,
    );
  }
  return c + dir * t;
}

/// 札を [anchor] に置く（札の中心を anchor に。画面からはみ出さないよう、
/// 縁の側に寄せる）。
class _Placed extends StatelessWidget {
  const _Placed({required this.anchor, required this.child});

  final Offset anchor;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: anchor.dx,
    top: anchor.dy,
    child: FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: child,
    ),
  );
}

/// 画面の外の店の数の吹き出し（ユーザーの指定）。**店舗限定の印（★ の丸）と
/// 数**だけを出し、吹き出しの尻尾で店のある方角を指す（矢印は使わない）。
class _Badge extends ConsumerWidget {
  const _Badge({
    required this.sector,
    required this.count,
    required this.kinds,
    required this.onTap,
  });

  final int sector;
  final int count;

  /// 並べる印（強い順。ユーザーの指定: 売り切れ・終売がある方角は ★☆ 3 のように）。
  final Set<LimitedAvailability> kinds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final label = ref.watch(messagesProvider).homeLimitedShops(count);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: CustomPaint(
          painter: _BubblePainter(
            angle: sector * math.pi / 4,
            fill: MapPalette.of(colors).panel,
            border: MapPalette.of(colors).panelBorder,
            shadow: Colors.black.withValues(alpha: colors.isDark ? 0.5 : 0.2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
            child: ExcludeSemantics(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final a in LimitedAvailability.values)
                    if (kinds.contains(a)) ...[
                      LimitedMark(availability: a, size: 18),
                      const SizedBox(width: 2),
                    ],
                  const SizedBox(width: 3),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
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

/// 吹き出しの形（角丸の四角 ＋ [angle] の向きへ出る尻尾）。[angle] は画面の上を
/// 0 とした時計回り（ラジアン）。尻尾は板の縁から [tail] だけ外へ出る。
class _BubblePainter extends CustomPainter {
  const _BubblePainter({
    required this.angle,
    required this.fill,
    required this.border,
    required this.shadow,
  });

  final double angle;
  final Color fill;
  final Color border;
  final Color shadow;

  static const tail = 7.0;
  static const tailHalfWidth = 5.0;
  static const radius = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final c = rect.center;
    final dir = Offset(math.sin(angle), -math.cos(angle));
    // 向きの符号は方角の番号から決める（sin / cos の誤差で、真横が
    // わずかに斜めと判定されないように）
    final sector = (angle / (math.pi / 4)).round() % 8;
    const signs = [
      (0, -1),
      (1, -1),
      (1, 0),
      (1, 1),
      (0, 1),
      (-1, 1),
      (-1, 0),
      (-1, -1),
    ];
    final sx = signs[sector].$1.toDouble();
    final sy = signs[sector].$2.toDouble();
    final ui.Path tailPath;
    if (sx != 0 && sy != 0) {
      // **斜めは板の角から出す**（ユーザーの指摘。辺の途中から斜めに出すと
      // 落ち着かない）。角を挟む 2 辺に付け根、角の外に先
      final corner = Offset(
        sx > 0 ? rect.right : rect.left,
        sy > 0 ? rect.bottom : rect.top,
      );
      // 付け根は角の丸みの内側（丸みより少し広い程度。広いと尻尾だけ大きく
      // 見える。ユーザーの指摘）
      const base = radius - 1;
      tailPath = ui.Path()
        ..moveTo(corner.dx - sx * base, corner.dy)
        ..lineTo(corner.dx + sx * tail * 0.4, corner.dy + sy * tail * 0.4)
        ..lineTo(corner.dx, corner.dy - sy * base)
        ..lineTo(corner.dx - sx * base, corner.dy - sy * base)
        ..close();
    } else {
      // 上下左右は辺の真ん中から出す
      final edge = Offset(c.dx + sx * (c.dx - 2), c.dy + sy * (c.dy - 2));
      final tip = Offset(c.dx + sx * (c.dx + tail), c.dy + sy * (c.dy + tail));
      final normal = Offset(-dir.dy, dir.dx) * tailHalfWidth;
      tailPath = ui.Path()
        ..moveTo(edge.dx + normal.dx, edge.dy + normal.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(edge.dx - normal.dx, edge.dy - normal.dy)
        ..close();
    }
    final path = ui.Path.combine(
      ui.PathOperation.union,
      ui.Path()..addRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(radius)),
      ),
      tailPath,
    );
    canvas
      ..drawShadow(path, shadow, 2, false)
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.angle != angle ||
      old.fill != fill ||
      old.border != border ||
      old.shadow != shadow;
}
