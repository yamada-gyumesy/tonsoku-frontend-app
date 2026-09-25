import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';

/// 店の印。**店舗限定を扱う店がひと目で分かる**ことが要件（Issue #8）。
///
/// - **普通の店** … 小さな点に面色の縁。**併設で塗り分ける**（[ShopDot]）。
///   681 軒が全国に散るので、引いた時に地図を埋めない大きさにする
/// - **店舗限定の店** … 一回り大きな丸にアイコン。状態で塗りを変える:
///   - 販売中 … **赤の塗り（`primary`）に白**。唯一の塗りなので一番目立つ
///   - 発売前 … 面色の地に赤（`primaryText`）の縁とアイコン
///   - 売り切れ … 薄い灰（`MapPalette.soldOut`）の塗りに白★。一時的な状態なので
///     形は販売中のまま、押せないボタンのように沈める
///   - 終売 … 同じ地に×（形で売り切れと分ける）
///
/// **塗りの赤（`primary`）は白を載せる塗りにだけ使う。** 地図の上に直接置く赤
/// （縁・アイコン）は `primaryText`（`AppColors.primary` の注記。ダークで 3:1 に
/// 届かない）。
///
/// **色だけに頼らない**（色覚の差・ダークでの見え方）。状態ごとにアイコンの形を
/// 変え、凡例（[MapLegend]）で同じ印を並べて説明する。
///
/// 営業していない店（一時閉店・開店前・閉店）は**薄く描く**（[dimmed]）。
class ShopMarker extends StatelessWidget {
  const ShopMarker({
    this.availability,
    this.brands = const [],
    this.dimmed = false,
    this.small = false,
    super.key,
  });

  /// 併設しているブランド（配信の `brands`）。**普通の店の点の塗り分け**に使う
  /// （[ShopDot]）。

  /// 店舗限定の状態。**普通の店は null。**
  final LimitedAvailability? availability;
  final List<String> brands;
  final bool dimmed;

  /// 引いた時（全国が入る倍率）の小さい点。
  final bool small;

  /// 押せる範囲（印の見た目より大きく取る。小さな点は指で押しにくい）。
  static const hitSize = 32.0;

  static const limitedSize = 26.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final a = availability;
    final Widget mark = a == null
        ? _dot(colors)
        : LimitedMark(availability: a, size: small ? 20 : limitedSize);
    return Center(
      child: Opacity(opacity: dimmed ? 0.45 : 1, child: mark),
    );
  }

  Widget _dot(AppColors colors) =>
      ShopDot(colors: ShopDot.colorsFor(brands, colors), size: small ? 8 : 12);
}

/// 店舗限定の印（丸とアイコン）。凡例でも同じものを使う。
class LimitedMark extends StatelessWidget {
  const LimitedMark({required this.availability, this.size = 26, super.key});

  final LimitedAvailability availability;
  final double size;

  static IconData iconOf(LimitedAvailability a) => switch (a) {
    LimitedAvailability.selling => Icons.star_rounded,
    LimitedAvailability.upcoming => Icons.schedule_rounded,
    // **売り切れは販売中の★を沈めた形**（ユーザーの指定。一時的な状態なので、
    // 販売中と同じ形のまま色だけ落とす。終売は×で形から変える）
    LimitedAvailability.soldOut => Icons.star_rounded,
    LimitedAvailability.ended => Icons.close_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (fill, ring, ink) = switch (availability) {
      // 塗りの赤に白。縁は面色（地図の上で輪郭を立てる）
      LimitedAvailability.selling => (
        colors.primary,
        colors.surface,
        colors.onPrimary,
      ),
      LimitedAvailability.upcoming => (
        colors.surface,
        colors.primaryText,
        colors.primaryText,
      ),
      // 薄い灰の塗りに白★（ユーザーの指定。販売中の赤の塗りを、押せない
      // ボタンのような薄い灰にした形。一時的に止まっているだけという意味）
      LimitedAvailability.soldOut => (
        MapPalette.of(colors).soldOut,
        colors.surface,
        colors.surface,
      ),
      LimitedAvailability.ended => (
        colors.hover,
        colors.border,
        colors.textSub,
      ),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.5 : 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(iconOf(availability), size: size * 0.62, color: ink),
    );
  }
}

/// 普通の店の点。**併設で塗り分ける**（ユーザーの指定）:
///
/// - 松のや専門店 … 緑
/// - 松屋併設 … 黄
/// - マイカリー食堂併設 … 茶
/// - 両方を併設（本番で 10 軒）… 左半分が黄、右半分が茶
///
/// 一度「左半分を緑にして右半分に併設の色」の形にしたが、見分けにくかった
/// （ユーザーの指摘）ので 1 色にした。絞り込みのチップにも同じ点を付ける
/// （`MapFilters`）。縁は面色。
class ShopDot extends StatelessWidget {
  const ShopDot({required this.colors, this.size = 12, super.key});

  /// 塗る色（1 色、または左右の 2 色）。
  final List<Color> colors;
  final double size;

  /// [brands]（配信の `brands`）の塗り分け。**`matsunoya` と知らないブランドは
  /// 数えない**（`ShopBrand` と同じ扱い）。
  static List<Color> colorsFor(List<String> brands, AppColors app) {
    final p = MapPalette.of(app);
    final annex = [
      if (brands.contains('matsuya')) p.annexMatsuya,
      if (brands.contains('mycurry')) app.brown,
    ];
    return annex.isEmpty ? [p.shop] : annex;
  }

  @override
  Widget build(BuildContext context) {
    final ring = context.colors.surface;
    return CustomPaint(
      size: Size.square(size),
      painter: _DotPainter(colors: colors, ring: ring),
    );
  }
}

class _DotPainter extends CustomPainter {
  const _DotPainter({required this.colors, required this.ring});

  final List<Color> colors;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final ringWidth = size.width >= 12 ? 1.5 : 1.0;
    canvas.drawCircle(c, r, Paint()..color = ring);
    final inner = Rect.fromCircle(center: c, radius: r - ringWidth);
    if (colors.length == 1) {
      canvas.drawOval(inner, Paint()..color = colors[0]);
    } else {
      // 左半分が先頭、右半分が 2 番目。drawArc の 0 は右（3 時）
      canvas
        ..drawArc(inner, math.pi / 2, math.pi, true, Paint()..color = colors[0])
        ..drawArc(
          inner,
          -math.pi / 2,
          math.pi,
          true,
          Paint()..color = colors[1],
        );
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) =>
      old.ring != ring || !listEquals(old.colors, colors);
}
