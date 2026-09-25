import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/config/app_config_provider.dart';
import 'package:tonsoku/core/theme/app_colors.dart';

/// 配信データの画像を出す。
///
/// **URL は必ず `AppConfig.cdnUrl()` を通す。** 配信データの絶対 URL（記事メタの
/// `thumbnail` など）と、こちらが組み立てる相対パス（クーポンのアイコン
/// `brands/x.webp` など）の 2 つが混ざっていて、見分ける印が無い。
///
/// 読み込み中は**同じ寸法のプレースホルダを置く**。高さが後から決まると、
/// 一覧をスクロールしている最中に行が飛ぶ。
class CdnImage extends ConsumerWidget {
  const CdnImage({
    required this.url,
    this.alt = '',
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.fallbackAsset,
    super.key,
  });

  /// サムネイル未設定の記事に出す画像。web の `DEFAULT_THUMBNAIL` と同じもの。
  /// **サムネイルを持たない記事は普通にある**（店舗の開店など。2026-09-25 の
  /// 本番で 36 本中 9 本）。
  static const defaultThumbnail = 'assets/brand/default-thumbnail.webp';

  final String url;
  final String alt;
  final BoxFit fit;

  /// 切り抜く時に残す側（チラシは上を残す）。
  final Alignment alignment;
  final double? width;
  final double? height;

  /// URL が空の時に出す同梱画像。指定しなければ地色のプレースホルダ。
  final String? fallbackAsset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final placeholder = ColoredBox(
      color: colors.border.withValues(alpha: 0.4),
      child: SizedBox(width: width, height: height),
    );

    if (url.isEmpty) {
      final fallback = fallbackAsset;
      if (fallback == null) return placeholder;
      return Semantics(
        label: alt.isEmpty ? null : alt,
        image: true,
        child: Image.asset(fallback, fit: fit, width: width, height: height),
      );
    }

    return Semantics(
      label: alt.isEmpty ? null : alt,
      image: true,
      child: CachedNetworkImage(
        imageUrl: ref.watch(appConfigProvider).cdnUrl(url),
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        placeholder: (context, _) => placeholder,
        // **読み込み失敗をアイコンだけで埋めない。** 枠と同じ地色に留めて、
        // 記事の並びの中で 1 枚だけ目立つのを避ける
        errorWidget: (context, _, _) => placeholder,
      ),
    );
  }
}
