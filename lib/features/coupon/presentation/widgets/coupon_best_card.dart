import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/coupon/domain/coupon_best_deal.dart';
import 'package:tonsoku/features/coupon/domain/coupon_format.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';
import 'package:tonsoku/shared/widgets/section_heading.dart';

/// 現在の最大還元率。web の `CoCouponBest`（gyumesy-frontend-app の
/// `CouponBestCard` を写し、とん速の見た目に合わせ直した）。
///
/// **この節の存在理由:** 率だけ出して終わりにしない。ポイ活の読者が知りたいのは
/// 「何を頼めば取り切れるか」で、そこまで出すと**競合の一覧サイトには無い画面**になる。
///
/// **上限のあるクーポンは「上限 ÷ 率」を超えると率が下がる。**
/// 「超えると戻りが増えない」ではない —— 上限が掛かるのは決済クーポンぶんだけで、
/// 松屋ポイントぶんには上限が無いので**戻る額自体は増え続ける**。落ちるのは率だけ。
///
/// ## gyumesy との違い
///
/// - **理論値の但し書きはカードの中**（web と同じ。gyumesy はカードの外）
/// - **注文例の金額は「合計」「還元」「実質」を語で並べる**（gyumesy は取り消し線と
///   矢印）。**還元と実質は配信が出している時だけ**（web の `?? null`）
/// - 合計の率と還元額は `primaryText`（gyumesy の `pink` は松屋の色）
class CouponBestCard extends ConsumerWidget {
  const CouponBestCard({
    required this.view,
    required this.onOpenArticle,
    super.key,
  });
  final BestDealView view;
  final ValueChanged<String> onOpenArticle;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(label: t.couponBestHeading),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            // **ライトは地色なし・枠だけ**（web も `dark:bg-brand-surface` だけ）
            color: colors.isDark ? colors.surface : null,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            // **要素の間隔**（web の `gap-3`）。**記号の前後の余白は
            // これに足し合わさる** —— `×` は 12 + 4 = 16px、`⇓` は
            // 12 + 8 = 20px で、web の `gap-3` ＋ `my-1` / `my-2` と同じ。
            //
            // **記号側の余白だけでは足りない。** ここを 0 にすると `×` の
            // 上下が 4px しか空かず、**注記の付いた要素の直後では上が
            // 詰まって見える**（実機で指摘）。
            spacing: 12,
            children: [
              for (var i = 0; i < view.parts.length; i++) ...[
                // 掛け算の記号にも前後の余白を持たせる
                // （詰めると要素が 1 かたまりに見える）
                if (i > 0) _Operator(text: '×', size: 16, gap: 4),
                // **要素ごとに鍵を持たせる。** 掛け合わせの中身は日によって
                // 入れ替わるので、鍵が無いと位置で対応付けられて別の要素の
                // 状態を引き継ぐ。**要素の矩形を名指しで測れる**ようにもなる
                // （記号の前後の余白を測るテストが、アイコンの位置を
                // 要素の上下端の代わりに使わずに済む）
                _Part(key: ValueKey(view.parts[i].label), part: view.parts[i]),
              ],
              // **前後に余白を取る。** 詰めると、上の要素の付帯情報のように見えて
              // 式が読めない
              _Operator(text: '⇓', size: 18, gap: 8),
              _Total(percent: view.totalPercent, label: t.couponRewardLabel),
              // 理論値の但し書き。**上限が効いていない日は出さない**
              // （率が下がらないので但し書きが嘘になる）。`spacing` の 12 が
              // web の `mt-3`
              if (view.targetText case final String target)
                Text(
                  target,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.625,
                    color: colors.textSub,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
        if (view.patterns.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            // **上限が効いていない日は `targetSpendYen` が意味を持たない**ので、
            // 金額を出さない見出しにする
            view.targetSpendYen == null
                ? t.couponPatternsLeadPlain
                : t.couponPatternsLead(
                    t.couponYen(formatNumber(view.targetSpendYen!)),
                  ),
            style: TextStyle(fontSize: 12, color: colors.textSub),
          ),
          const SizedBox(height: 8),
          for (final (i, p) in view.patterns.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            _Pattern(pattern: p, onOpenArticle: onOpenArticle),
          ],
        ],
      ],
    );
  }
}

class _Operator extends StatelessWidget {
  const _Operator({required this.text, required this.size, required this.gap});
  final String text;
  final double size;
  final double gap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: gap),
    child: Text(
      text,
      style: TextStyle(
        fontSize: size,
        height: 1,
        color: context.colors.textSub,
      ),
    ),
  );
}

class _Part extends StatelessWidget {
  const _Part({required this.part, super.key});
  final BestDealPartView part;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (part.iconKey case final String icon) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: CdnImage(url: icon, width: 32, height: 32),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                part.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatPercent(part.percent),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        if (part.noteText != null) ...[
          const SizedBox(height: 6),
          Text(
            part.noteText!,
            style: TextStyle(
              fontSize: 11,
              height: 1,
              color: colors.textSub,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// 合計。**数字は 40px、「還元」は 20px。**
///
/// 同じ大きさにはしない（率が主役）が、小さすぎると単位ではなく注記に見えるので
/// 数字の半分ほどに取る。色は `primaryText`（面に対してライト 7.20:1 /
/// ダーク 5.22:1）。**塗りの `primary` にしない**（地に直接置く赤）。
class _Total extends StatelessWidget {
  const _Total({required this.percent, required this.label});
  final double percent;
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formatPercent(percent),
          style: TextStyle(
            fontSize: 40,
            height: 1,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.bold,
            color: colors.primaryText,
          ),
        ),
      ],
    );
  }
}

/// 取り切る買い方 1 件。
///
/// **メニューは縦積み。横並びに戻さないこと。** 名前が長い組み合わせ
/// （「松屋オリジナルソースローストビーフ」＋「単品冷や汁」）では 1 件目だけで
/// 幅を使い切り、`+` が 1 件目の右上に取り残されて 2 件目との関係が読めなくなる。
///
/// **合計・還元・実質は配信が計算した数字をそのまま出す。** こちらで
/// 「合計 × 率」を掛けると一致しない（配信は施策ごとに円未満を切り捨てて
/// 上限を当ててから足す）。
class _Pattern extends ConsumerWidget {
  const _Pattern({required this.pattern, required this.onOpenArticle});

  final BestDealPatternView pattern;
  final ValueChanged<String> onOpenArticle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    String yen(int v) => t.couponYen(formatNumber(v));
    const tabular = [FontFeature.tabularFigures()];
    final back = pattern.backYen;
    final net = pattern.netYen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.isDark ? colors.surface : null,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // web の `gap-1`
        spacing: 4,
        children: [
          for (final (i, item) in pattern.items.indexed) ...[
            if (i > 0)
              ExcludeSemantics(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1,
                    color: colors.textSub,
                  ),
                ),
              ),
            _Item(item: item, onOpenArticle: onOpenArticle),
          ],
          const SizedBox(height: 8),
          // **金額の行は中央寄せ**（web の `text-center`）。**幅を明示しないと
          // 効かない** —— 親が `start` なので中身の幅に縮む（gyumesy の実機）
          SizedBox(
            width: double.infinity,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${t.couponTotalLabel} ',
                    style: TextStyle(fontSize: 14, color: colors.text),
                  ),
                  TextSpan(
                    text: yen(pattern.totalYen),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                      fontFeatures: tabular,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // **還元が無い回は行ごと消す**（数字を 1 つも嘘にしない）
          if (back != null)
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                children: [
                  _amount(
                    t.couponBackLabel,
                    yen(back),
                    colors,
                    // **戻りだけ色を付ける。** 3 つが同じ濃さだと、どれが得なのかが
                    // 読めない
                    colors.primaryText,
                  ),
                  if (net != null)
                    _amount(t.couponNetLabel, yen(net), colors, colors.text),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _amount(String label, String value, AppColors colors, Color color) =>
      Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: 11,
            color: colors.textSub,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      );
}

/// 注文例の品 1 つ。**記事がある品だけリンクにする**（本番では 111 件中 16 件で、
/// リンクが無いほうが普通。無い品を押せるように見せない）。
class _Item extends ConsumerWidget {
  const _Item({required this.item, required this.onOpenArticle});

  final BestDealItemView item;
  final ValueChanged<String> onOpenArticle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final slug = item.articleSlug;
    final price = item.priceYen;
    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // **絵・値段は配信が出している時だけ**（古い形の配信は名前しか持たない）
        if (item.thumbnail.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CdnImage(url: item.thumbnail, width: 40, height: 40),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                  decoration: slug == null ? null : TextDecoration.underline,
                  decorationColor: colors.text,
                ),
              ),
              // 値段は**値引き反映後の実効価格**（配信が計算したもの）
              if (price != null)
                Text(
                  t.couponYen(formatNumber(price)),
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
    );
    if (slug == null) return body;
    return Semantics(
      link: true,
      child: GestureDetector(onTap: () => onOpenArticle(slug), child: body),
    );
  }
}
