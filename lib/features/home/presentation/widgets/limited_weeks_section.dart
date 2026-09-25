import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/shared/models/limited_week.dart';
import 'package:tonsoku/shared/utils/character.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';
import 'package:tonsoku/shared/widgets/section_heading.dart';

/// ホームの「店舗限定」の節。web の `CoLimitedWeeks` を移したもの。
///
/// **週ごとにカードを必ず並べる**（web のユーザー設計）:
///
/// - 売っている品 … 普通のカード
/// - 出なかった週 … のや子のグレーのカード（「今週はなし」）
/// - 終売した品 … 写真をグレーにして、真ん中に「終売」の判子を斜めに押す
///
/// **「なし」は配信が確定した週だけ出す**（`status: 'none'`）。`pending` の週は
/// 何も出さない —— 推測で「なし」を出すと、検知が遅れただけの週に嘘が出る。
///
/// **1 枚も無ければ節ごと出さない**（配信がまだ無い・全部 pending）。
class LimitedWeeksSection extends ConsumerWidget {
  const LimitedWeeksSection({
    required this.weeks,
    required this.onOpenArticle,
    super.key,
  });

  final List<LimitedWeek> weeks;
  final ValueChanged<String> onOpenArticle;

  /// 並べる週の数。**新しい順に 4 週**（横に流すので、それ以上は見られない。web と同じ）
  static const maxWeeks = 4;

  /// 1 枚の幅（**左右の余白を除いた幅**に対する比。web の `w-[45%]`）。
  /// **2.1〜2.2 枚見える幅**（web のユーザー指定。2.5 枚では 1 枚が細く縦に
  /// 長すぎた）。右端が少し見えていることが「続きがある」の合図になる。
  ///
  /// **画面幅に掛けないこと。** web の `%` は横に流す器の中身の幅（器は `-mx-4`
  /// で紙面の端まで出し、`px-4` で余白を戻している）に対する比で、画面幅より
  /// 32px 狭い。画面幅に掛けると 1 枚が 14px 広がり、**3 枚目がちょうど画面の外へ
  /// 押し出されて、2 枚がすっぽり収まった形になる** ―― 横に送れることが
  /// 分からなくなる（実際にそうなっていた。ユーザーの指摘）。
  static const _cardWidthRatio = 0.45;

  /// 横に流す器の左右の余白（web の `px-4`）。
  static const _inset = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final cards = limitedCards(weeks, t, today: todayInJst());
    if (cards.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = (width - _inset * 2) * _cardWidthRatio;

    return Padding(
      // 節の間は `mb-8`（web）
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeading(
              label: t.homeLimitedHeading,
              lead: t.homeLimitedLead,
            ),
          ),
          const SizedBox(height: 12),
          // **紙面の端まで流す**（web の `-mx-4 px-4`）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _inset),
            // **カードの高さを揃える**（web はカードが `flex-1` で列の高さに伸びる）
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, card) in cards.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    SizedBox(
                      width: cardWidth,
                      child: _CardColumn(
                        card: card,
                        onOpenArticle: onOpenArticle,
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

/// カード 1 枚ぶん。**画面に出す文字まで決めた形**で持つ（組み立てを
/// テストで確かめられるように、描画から切り離してある）。
sealed class LimitedCard {
  const LimitedCard({required this.week});

  /// カードの上に出す週（`9/23週`）。**週はカードの外に出す**（web のユーザー指定。
  /// カードの中の日付だけでは、どの週の話かが一目で分からない）
  final String week;
}

class LimitedItemCard extends LimitedCard {
  const LimitedItemCard({
    required super.week,
    required this.name,
    required this.image,
    required this.slug,
    required this.shops,
    required this.ended,
  });

  final String name;
  final String image;
  final String? slug;
  final String shops;
  final bool ended;
}

class LimitedNoneCard extends LimitedCard {
  const LimitedNoneCard({required super.week, required this.label});

  final String label;
}

/// 週の並びをカードに起こす。web の `CoLimitedWeeks` の `cards`。
///
/// [today] は JST の `YYYY-MM-DD`（`todayInJst`）。「今週はなし」と「この週はなし」を
/// 分けるのに使う。
@visibleForTesting
List<LimitedCard> limitedCards(
  List<LimitedWeek> weeks,
  AppMessages t, {
  required String today,
}) {
  String md(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${int.tryParse(parts[1]) ?? parts[1]}/${int.tryParse(parts[2]) ?? parts[2]}';
  }

  // **知らない `status` は `pending` と同じく出さない**（web は `pending` だけを
  // 落とすが、とん速の配信は 3 値に閉じていて、増えた値を「品がある」とも
  // 「なし」とも決められない）
  final shown = weeks
      .where((w) => w.hasItems || w.isNone)
      .take(LimitedWeeksSection.maxWeeks);

  return [
    for (final w in shown)
      if (w.isNone)
        LimitedNoneCard(
          week: t.homeLimitedWeek(md(w.weekStart)),
          // `YYYY-MM-DD` のまま文字列で比べる（web と同じ）
          label:
              w.weekStart.compareTo(today) <= 0 &&
                  today.compareTo(w.weekEnd) <= 0
              ? t.homeLimitedNoneThisWeek
              : t.homeLimitedNonePast,
        )
      else
        for (final item in w.items)
          LimitedItemCard(
            week: t.homeLimitedWeek(md(w.weekStart)),
            name: item.name,
            image: item.imageUrl,
            slug: item.articleSlug,
            // **店の数の出し方は 3 通り**（web のユーザー指定）:
            // - 終売した品 … 確定時点の数のまま（判子で伝わる）
            // - 一部の店で売り終わった品 … 今売っている数と売り終わった数
            // - それ以外 … 今売っている数
            shops: item.ended
                ? t.homeLimitedShops(item.shopCount)
                : item.shopsEnded > 0
                ? t.homeLimitedShopsWithEnded(item.shopsLive, item.shopsEnded)
                : t.homeLimitedShops(item.shopsLive),
            ended: item.ended,
          ),
  ];
}

class _CardColumn extends StatelessWidget {
  const _CardColumn({required this.card, required this.onOpenArticle});

  final LimitedCard card;
  final ValueChanged<String> onOpenArticle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final card = this.card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          // **週の字はカードの中の字と同じだけ内に入れる**（web の `px-2`。
          // カードの端にそろえると、角丸で削れた角の上に字だけが突き出して見えた）
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Text(
            card.week,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Expanded(
          child: switch (card) {
            LimitedItemCard() => _ItemCard(
              card: card,
              onTap: card.slug == null ? null : () => onOpenArticle(card.slug!),
            ),
            LimitedNoneCard() => _NoneCard(card: card),
          },
        ),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.card, required this.onTap});

  final LimitedItemCard card;
  final VoidCallback? onTap;

  /// 終売した品の写真。**色を抜き切らず、少し残す**（web の `grayscale(0.7)`。
  /// 全部グレーにして半透明にしたら薄すぎて何の品か分からなかった）。
  ///
  /// 値は CSS の `grayscale(0.7)` の行列（Filter Effects の定義に 0.7 を入れたもの）。
  static const _endedFilter = ColorFilter.matrix(<double>[
    0.4488, 0.5006, 0.0505, 0, 0, //
    0.1488, 0.8006, 0.0505, 0, 0, //
    0.1488, 0.5006, 0.3505, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget image = AspectRatio(
      // **写真は横長に切る**（4:3。正方形だとカードが縦に長くなりすぎた）
      aspectRatio: 4 / 3,
      child: ColoredBox(
        color: colors.hover,
        child: CdnImage(url: card.image, width: double.infinity),
      ),
    );
    if (card.ended) {
      image = Opacity(
        opacity: 0.75,
        child: ColorFiltered(colorFilter: _endedFilter, child: image),
      );
    }

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                image,
                // **終売でも文字は薄めない**（web: 副テキストを 70% にすると
                // ライトで 3.09:1 になり文字の基準を割る。終売は写真と判子で伝わる）
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // **品名は 2 行ぶんの高さを必ず取る**（web の `min-h-[2lh]`。
                      // 1 行の品と 2 行の品で下の店舗数の位置がずれないように）
                      SizedBox(
                        height: 13 * 1.375 * 2,
                        child: Text(
                          card.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.375,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // **日付は出さない**（どの週かはカードの上に出ている）
                      Text(
                        card.shops,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSub,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (card.ended) const _EndedStamp(),
          ],
        ),
      ),
    );
  }
}

/// 終売の判子。**写真の真ん中に斜めに押す**（web のユーザー設計）。
class _EndedStamp extends ConsumerWidget {
  const _EndedStamp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final label = ref.watch(messagesProvider).homeLimitedEnded;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          // web の `top: 36%; left: 50%; translate(-50%, -50%)`
          alignment: Alignment(0, 0.36 * 2 - 1),
          child: Transform.rotate(
            angle: -14 * math.pi / 180,
            child: Semantics(
              label: label,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  // **地は面色の 95%**（web: 85% ではダークで白い写真の上に
                  // 乗ると 3.28:1 まで落ちた。95% なら写真が白でも黒でも
                  // ライト・ダークとも 4.5:1 を超える）
                  color: colors.surface.withValues(alpha: 0.95),
                  border: Border.all(color: colors.primaryText, width: 3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.2,
                      letterSpacing: 24 * 0.1,
                      color: colors.primaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 出なかった週。**のや子の線を「この週はなし」の文字と同じ色で描く**
/// （web のユーザー指定）。丸の枠も同じ色で、**線と枠をまとめて少し薄くする**
/// （`opacity-60`。別々に薄めると濃さが食い違う）。
///
/// **絵の線は SVG に赤で焼いてある**（配信の絵は変えない）。web はビルド時に塗りを
/// `currentColor` に差し替えて埋めているが、アプリは色で塗り替える
/// （`BlendMode.srcIn`。線画 1 色なので同じ結果になる）。
class _NoneCard extends StatelessWidget {
  const _NoneCard({required this.card});

  final LimitedNoneCard card;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      // web の `min-h-40`
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.hover,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.6,
            child: Container(
              width: 56,
              height: 56,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.textSub),
              ),
              child: ClipOval(
                child: SvgPicture.network(
                  expressionUrl('confused'),
                  colorFilter: ColorFilter.mode(
                    colors.textSub,
                    BlendMode.srcIn,
                  ),
                  // 取れなければ丸だけ残す（web は `<img>` の赤い線に落とす）
                  errorBuilder: (context, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card.label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.textSub),
          ),
        ],
      ),
    );
  }
}
