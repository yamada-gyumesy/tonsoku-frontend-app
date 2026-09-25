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

/// 記事一覧の 1 行。web の `CoArticleCard` に合わせて、左にサムネイル・
/// 右にタイトルと日付・分類を置く。
///
/// **区切り線は左右の余白の内側に引く**（web のユーザー指定）。余白は外側
/// （[InkWell] の内側の `Padding`）が持ち、線は内側の箱が持つ ―― 押した時の地は
/// 紙面の端まで、線は文字の頭と同じ位置から。**置く側は画面幅いっぱいに置くこと**
/// （器に余白を持たせると二重になる）。
class ArticleCard extends ConsumerWidget {
  const ArticleCard({
    required this.article,
    required this.onTap,
    this.categories = const [],
    this.tags = const [],
    this.flushTop = false,
    this.rank,
    this.compact = false,
    super.key,
  });

  final ArticleMeta article;
  final VoidCallback onTap;

  /// 配信のカテゴリ定義。**ラベルの正は配信**（`categories.json`）。
  final List<Category> categories;

  /// 配信のタグ定義。空で渡すとラベルが引けず slug がそのまま出る。
  final List<Tag> tags;

  /// 上の余白を持たない（一覧の先頭の 1 件だけに使う）。
  ///
  /// **上に余白を持つ帯（記事一覧の絞り込み）の直下に置く時に要る。** web は
  /// 帯に上下 16px を持たせたうえで一覧の頭を `margin-bottom: -1rem` で重ね、
  /// チップと 1 件目の間が 32px 空くのを防いでいる（`CoArticleFilter`）。
  /// スリバーは負の余白で重ねられないので、1 件目の側で削る。
  final bool flushTop;

  /// ランキングの順位。**指定するとサムネイルの左上に順位バッジを載せる**
  /// （web の `CoArticleCard` の `rank`。4 位以下のランキングで使う）。
  final int? rank;

  /// 見出しを一段小さくする（web の `compact`。`text-sm`）。**ランキングの
  /// 4 位以下では必須**（上位 3 件のカードより見出しが大きい逆転を起こさない）。
  final bool compact;

  /// web の `w-32 h-24`。
  static const _thumbnailWidth = 128.0;
  static const _thumbnailHeight = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final locale = ref.watch(localeControllerProvider);
    final category = _category();

    return InkWell(
      onTap: onTap,
      highlightColor: colors.hover,
      splashColor: colors.hover,
      child: Padding(
        // web の `px-4`
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          // web の `py-4 border-b`
          padding: EdgeInsets.only(top: flushTop ? 0 : 16, bottom: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          // **サムネイルの高さで頭打ちにしない。** web はテキスト側が伸びれば
          // カードごと伸びる。ここを固定にすると 3 行目が欠ける（gyumesy と同じ）
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  // web の `rounded overflow-hidden bg-brand-bg border`
                  child: Container(
                    width: _thumbnailWidth,
                    height: _thumbnailHeight,
                    decoration: BoxDecoration(
                      color: colors.bg,
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    // **一覧では小さい版を使う**（原寸は幅 800）。
                    // サムネイルの無い記事は既定の絵に落とす（web の `thumbnailSrc`）
                    child: Stack(
                      children: [
                        CdnImage(
                          url: article.thumbnailSmall,
                          width: _thumbnailWidth,
                          height: _thumbnailHeight,
                          fallbackAsset: CdnImage.defaultThumbnail,
                        ),
                        if (rank case final int rank)
                          // web の `absolute top-0.5 left-0.5`
                          Positioned(
                            top: 2,
                            left: 2,
                            child: RankBadge(rank: rank, small: true),
                          ),
                      ],
                    ),
                  ),
                ),
                // web の `gap-3`
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        // web の `text-base leading-normal tracking-[0.04em]`
                        // （`compact` は `text-sm`）
                        style: TextStyle(
                          fontSize: compact ? 14 : 16,
                          height: 1.5,
                          letterSpacing: (compact ? 14 : 16) * 0.04,
                          fontWeight: FontWeight.bold,
                          color: colors.text,
                        ),
                      ),
                      // 日付と分類は下端に寄せる（web の `mt-auto pt-2`）
                      const Spacer(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            formatRelativeDate(article.createdAt, locale),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSub,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // **日付は縮めない、チップの帯だけ流す。** 折り返すと
                          // カードの高さが行ごとにばらつくので、横スクロールに
                          // 逃がして 1 行に固定する（web と同じ）
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
                                    LabelChip.tag(label: _tagLabel(tag)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 記事に出すカテゴリ。**配信の `categories` の先頭 1 件**（配信側は 1 件しか
  /// 入れない）。**一覧に無い slug なら出さない**（web の `articleCategory`。
  /// ラベルもページも無いので、出しようがない）。
  Category? _category() {
    final slug = article.categories.firstOrNull;
    if (slug == null) return null;
    return categories.where((c) => c.slug == slug).firstOrNull;
  }

  /// **タグは未定義の slug も slug のまま出す**（web の `tagLabel`）。
  String _tagLabel(String slug) =>
      tags.where((t) => t.slug == slug).map((t) => t.label).firstOrNull ?? slug;
}
