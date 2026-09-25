import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/config/app_config_provider.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/article/presentation/widgets/image_viewer.dart';
import 'package:tonsoku/features/coupon/data/coupon_repository.dart';
import 'package:tonsoku/features/coupon/domain/coupon_row.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/coupon.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';
import 'package:tonsoku/shared/widgets/section_heading.dart';

/// ホームの「お得なクーポン」。web の `CoCouponCards`。
///
/// **大きめのカードを横に流す**（2.1〜2.2 枚見える幅。web のユーザー指定）。
///
/// **出すのは券売機で使えるクーポンだけ**（公式 X と TikTok で配られるもの。
/// [dealCouponWhere]）。行の組み立て（`offerRows`）はクーポンタブと共有し、
/// **見た目だけホーム用に変えている**。
///
/// - **絵はチラシ**（QR コードでないほう）。無ければ配布元のアイコンを大きく出す
/// - **QR コードはカードの下のボタンで開く**（券売機の前でそのまま使えるように）
/// - **1 件しかない時も幅は同じまま左に寄せる**（件数でカードの形が変わらないように）
/// - **いま使えるものだけ**（予告はクーポンタブの別の節が受け持つ）
class DealCouponSection extends ConsumerWidget {
  const DealCouponSection({
    required this.onOpenArticle,
    required this.onOpenCoupon,
    super.key,
  });

  final ValueChanged<String> onOpenArticle;
  final VoidCallback onOpenCoupon;

  /// ホームに出すクーポンか（web の `index.astro`）。**見分けは `how_to_get`**。
  ///
  /// **一覧を定数に起こして種類バッジと共有しないこと。** ここが答えているのは
  /// 「ホームに出す施策か」で、バッジが答えているのは「どの絵を出すか」――
  /// たまたま同じ 2 値なだけで、片方だけが増える日がある（web の判断）。
  ///
  /// **知らない値は出さない側に倒れる**（配信が新しい出どころを出し始めても、
  /// ここに足すまでホームには出ない。クーポンタブには普通の行として出る）。
  static bool dealCouponWhere(CouponOffer offer) =>
      offer.howToGet == 'x' || offer.howToGet == 'tiktok';

  /// web の `w-[44%]`。**左右の余白を除いた幅に対する比**（画面幅に掛けると
  /// 3 枚目が画面の外へ押し出され、横に送れることが分からなくなる。理由の全文は
  /// `LimitedWeeksSection._cardWidthRatio`）。
  static const _cardWidthRatio = 0.44;

  /// 横に流す器の左右の余白（web の `px-4`）。
  static const _inset = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupon = ref.watch(couponProvider).value;
    if (coupon == null) return const SizedBox.shrink();
    final t = ref.watch(messagesProvider);
    final tags = ref.watch(tagsProvider).value ?? const [];
    // **記事へのリンクは、一覧に居る slug だけ**（施策は記事より寿命が長い）
    final slugs = <String>{
      for (final a in ref.watch(feedProvider).value ?? const <ArticleMeta>[])
        a.slug,
    };
    final rows = offerRows(
      coupon,
      locale: ref.watch(localeControllerProvider),
      t: t,
      tagLabels: {for (final tag in tags) tag.slug: tag.label},
      slugs: slugs,
      where: dealCouponWhere,
    );
    // **1 件も無ければ節ごと出さない**
    if (rows.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final cardWidth =
        (MediaQuery.sizeOf(context).width - _inset * 2) * _cardWidthRatio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeading(
              label: t.homeDealCoupon,
              trailing: _ViewCouponLink(
                label: t.homeViewCoupon,
                color: colors.textSub,
                onTap: onOpenCoupon,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _inset),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, row) in rows.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    SizedBox(
                      width: cardWidth,
                      child: _CouponCard(
                        row: row,
                        onTap: row.articleSlug != null
                            ? () => onOpenArticle(row.articleSlug!)
                            : onOpenCoupon,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 節の右の「クーポン一覧 >」（web の `CaLink` の組み方）。
class _ViewCouponLink extends StatelessWidget {
  const _ViewCouponLink({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    link: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_activity_outlined, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              decoration: TextDecoration.underline,
              decorationColor: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.arrow_forward_ios, size: 10, color: color),
        ],
      ),
    ),
  );
}

class _CouponCard extends ConsumerWidget {
  const _CouponCard({required this.row, required this.onTap});

  final CouponRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final config = ref.watch(appConfigProvider);
    final flyer = row.images.where((img) => !img.isCode).firstOrNull;
    final code = row.images.where((img) => img.isCode).firstOrNull;
    final icon = row.iconUrl;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // **チラシは横長に切って上を残す**（4:3。チラシは題と主役の品が
                  // 上にある。全体は記事を開けば見られる）
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ColoredBox(
                      color: colors.hover,
                      child: flyer != null
                          ? CdnImage(
                              url: flyer.url,
                              width: double.infinity,
                              alignment: Alignment.topCenter,
                            )
                          : icon == null
                          ? const SizedBox.shrink()
                          : Center(
                              child: FractionallySizedBox(
                                widthFactor: 0.5,
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: CdnImage(
                                      url: config.cdnUrl(icon),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${row.sourceMark ?? ''}${row.name}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.375,
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                          ),
                          // **値段は小さくてよい。色で目立つ**（大きくすると題より
                          // 重くなる。web のユーザー指摘）
                          if (row.primary case final primary?) ...[
                            const SizedBox(height: 2),
                            Text(
                              primary,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.375,
                                fontWeight: FontWeight.bold,
                                color: colors.primaryText,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          const SizedBox(height: 4),
                          Text(
                            row.period,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSub,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (code != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: InkWell(
                onTap: () => showImageViewer(
                  context,
                  url: config.cdnUrl(code.url),
                  alt: code.label,
                  isCode: true,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2, size: 16, color: colors.text),
                      const SizedBox(width: 4),
                      Text(
                        code.label,
                        style: TextStyle(fontSize: 13, color: colors.text),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
