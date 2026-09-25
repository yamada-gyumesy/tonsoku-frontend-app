import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/ranking/presentation/widgets/rank_badge.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';
import 'package:tonsoku/shared/widgets/label_chip.dart';

/// 上位 3 件のカード。web の `CoRankingCard`（gyumesy-frontend-app の
/// `RankingCard` を写し、とん速の web に合わせ直した）。
///
/// **3 枚とも同じ大きさにする。** 1 枚だけ大きくすると、配信サムネイルの解像度を
/// 超える。順位の差はバッジの色で示す。
///
/// ## gyumesy との違い（とん速の web に合わせたもの）
///
/// - **画像の箱は 4:3 で固定**（web の `aspect-[4/3]`）。とん速の `thumbnail` は
///   松のや公式サイトの原本 URL のまま来ていて、縦長・横長が混ざる。比を箱が
///   持てば、どんな原本が来ても切り取って揃う（web の注記）
/// - **左右の余白はカードが持ち、区切り線はその内側に引く**（web のユーザー指定。
///   `ArticleCard` と必ず同じにする ―― 同じ一覧の下半分はあちらなので、ずれると
///   上下で文字の頭と線の端がそろわない）
/// - バッジは画像の角から 4px 浮かせる（web の `top-1 left-1`）
class RankingCard extends ConsumerWidget {
  const RankingCard({
    required this.rank,
    required this.article,
    required this.onTap,
    this.categories = const [],
    this.tags = const [],
    super.key,
  });

  final int rank;
  final ArticleMeta article;
  final VoidCallback onTap;
  final List<Category> categories;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final locale = ref.watch(localeControllerProvider);
    // **一覧に無い slug のカテゴリは出さない**（`ArticleCard` と同じ。web の
    // `articleCategory`）
    final slug = article.categories.firstOrNull;
    final category = slug == null
        ? null
        : categories.where((c) => c.slug == slug).firstOrNull;

    return InkWell(
      onTap: onTap,
      highlightColor: colors.hover,
      splashColor: colors.hover,
      child: Padding(
        // web の `px-4`（区切り線はこの内側）
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          // web の `py-4 border-b`
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ColoredBox(
                    color: colors.bg,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CdnImage(
                          url: article.thumbnail,
                          alt: article.title,
                          fallbackAsset: CdnImage.defaultThumbnail,
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: RankBadge(rank: rank),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // web の `pt-3`
              const SizedBox(height: 12),
              Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                // web の `text-base leading-normal tracking-[0.04em]`
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 16 * 0.04,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
              // web の `mt-2`
              const SizedBox(height: 8),
              // **タグまで出す。** 4 位以下（`ArticleCard`）は出しているので、
              // ここで落とすと同じ一覧で下位のほうが情報量が多くなる
              Row(
                children: [
                  Text(
                    formatRelativeDate(article.createdAt, locale),
                    style: TextStyle(fontSize: 12, color: colors.textSub),
                  ),
                  const SizedBox(width: 6),
                  // 日付は縮めない、チップの帯だけ流す（`ArticleCard` と同じ）
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (category != null)
                            LabelChip.category(
                              label: category.label,
                              slug: category.slug,
                            ),
                          for (final tag in article.tags) ...[
                            const SizedBox(width: 6),
                            LabelChip.tag(
                              label:
                                  tags
                                      .where((t) => t.slug == tag)
                                      .map((t) => t.label)
                                      .firstOrNull ??
                                  tag,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
