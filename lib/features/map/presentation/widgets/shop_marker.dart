import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';

/// 店の印。**店舗限定を扱う店がひと目で分かる**ことが要件（Issue #8）。
///
/// - **普通の店** … 茶（`brown`）の小さな点に面色の縁。681 軒が全国に散るので、
///   引いた時に地図を埋めない大きさにする
/// - **店舗限定の店** … 一回り大きな丸にアイコン。状態で塗りを変える:
///   - 販売中 … **赤の塗り（`primary`）に白**。唯一の塗りなので一番目立つ
///   - 発売前 … 面色の地に赤（`primaryText`）の縁とアイコン
///   - 売り切れ … 面色の地に副テキストの縁とアイコン
///   - 終売 … hover の地に罫線の縁、副テキストのアイコン（一番沈める）
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
    this.dimmed = false,
    this.small = false,
    super.key,
  });

  /// 店舗限定の状態。**普通の店は null。**
  final LimitedAvailability? availability;
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

  Widget _dot(AppColors colors) {
    final size = small ? 7.0 : 11.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.brown,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: small ? 1 : 1.5),
      ),
    );
  }
}

/// 店舗限定の印（丸とアイコン）。凡例でも同じものを使う。
class LimitedMark extends StatelessWidget {
  const LimitedMark({required this.availability, this.size = 26, super.key});

  final LimitedAvailability availability;
  final double size;

  static IconData iconOf(LimitedAvailability a) => switch (a) {
    LimitedAvailability.selling => Icons.star_rounded,
    LimitedAvailability.upcoming => Icons.schedule_rounded,
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
