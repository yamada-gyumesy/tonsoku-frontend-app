import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/features/coupon/domain/coupon_channels.dart';
import 'package:tonsoku/features/coupon/domain/coupon_format.dart';
import 'package:tonsoku/features/coupon/domain/coupon_row.dart';
import 'package:tonsoku/shared/models/coupon.dart';

/// 最大還元の組み合わせを画面用に解決したもの。web の `bestDealView`
/// （gyumesy-frontend-app の `coupon_best_deal.dart` を写し、とん速の違いを入れた）。
///
/// ## gyumesy との違い
///
/// - アイコンは CDN に置いてあるものだけ（`cdnIconKey`。無ければ null で絵を出さない）
/// - 品の値段・戻る額・実質は **null を取りうる**（web が `?? null` で受けている。
///   配信が契約に反した回に、その行だけを消して踏みとどまる）
class BestDealPartView {
  const BestDealPartView({
    required this.label,
    required this.percent,
    required this.iconKey,
    required this.noteText,
  });

  final String label;
  final double percent;

  /// CDN のアイコンのキー（`brands/paypay.webp`）。置いていなければ null。
  final String? iconKey;

  /// 上限・ランクの前提。**要素ごとに持つ**（付いている理由が要素によって違う。
  /// 全体の注記にすると、掛かっていない側にも同じ前提が付いて嘘になる）。
  final String? noteText;
}

class BestDealItemView {
  const BestDealItemView({
    required this.name,
    required this.priceYen,
    required this.articleSlug,
    required this.thumbnail,
  });

  final String name;
  final int? priceYen;

  /// **一覧に居る slug だけ**（品は施策より寿命が短い）。
  final String? articleSlug;
  final String thumbnail;
}

class BestDealPatternView {
  const BestDealPatternView({
    required this.items,
    required this.totalYen,
    required this.backYen,
    required this.netYen,
  });

  final List<BestDealItemView> items;
  final int totalYen;

  /// 戻る額と実質負担。**こちらでは計算しない**（配信は施策ごとに円未満を切り捨てて
  /// 上限を当ててから足すので、「合計 × 合計率」では一致しない）。
  final int? backYen;
  final int? netYen;
}

class BestDealView {
  const BestDealView({
    required this.parts,
    required this.totalPercent,
    required this.targetText,
    required this.targetSpendYen,
    required this.patterns,
  });

  final List<BestDealPartView> parts;
  final double totalPercent;

  /// **合計側の但し書き**（この率で頼める上限の金額は組み合わせ全体の性質）。
  /// **上限が効いていない日・金額が無い日は null**（率が下がらないので但し書きが嘘になる）。
  final String? targetText;
  final int? targetSpendYen;
  final List<BestDealPatternView> patterns;
}

BestDealView? bestDealView({
  required Coupon coupon,
  required AppMessages t,
  required Map<String, String> tagLabels,
  required Set<String> slugs,
}) {
  final deal = coupon.bestDeal;
  if (deal == null) return null;

  final byId = {
    for (final o in [...coupon.offers, ...coupon.upcoming]) o.id: o,
  };

  // 前提にしている会員ランクの付与率。**倍率クーポンの率はこれに掛かっている**ので、
  // 率だけ出すと何を前提にした数字なのか読めない。店舗払いは系統が無いので出せない
  final rateKey = rateKeyOf(deal.channel);
  final basePercent = rateKey == null
      ? null
      : coupon.ranks
            .where((r) => r.id == deal.rank)
            .map((r) => r.rates[rateKey])
            .whereType<double>()
            .firstOrNull;

  // **`deal.cap_yen` のフォールバックは「引けなかった要素」にだけ掛ける。**
  // 引けた要素が既に上限を持っているなら、そちらが正しいので何もしない
  final resolved = [
    for (final p in deal.parts) p.offerId == null ? null : byId[p.offerId],
  ];
  final hasResolvedCap = resolved.any((o) => o?.capYen != null);
  final missingCount = [
    for (var i = 0; i < deal.parts.length; i++)
      if (deal.parts[i].offerId != null && resolved[i] == null) i,
  ].length;

  final parts = <BestDealPartView>[];
  for (var i = 0; i < deal.parts.length; i++) {
    final part = deal.parts[i];
    final offer = resolved[i];
    // **引けない offer_id を松屋ポイント扱いにしない。** 期限切れで落ちた施策を
    // 指したままの best_deal が届くと、決済クーポンの要素が別物の名前とアイコンで
    // 出てしまう。その時は `brand` から名前を出し、brand も無い時だけ松屋ポイント
    final brandLabel = part.brand == null
        ? null
        : (tagLabels[part.brand!] ?? part.brand);
    final isMissing = part.offerId != null && offer == null;
    // 引けない要素が 2 つ以上ある時はどちらに付くか決められないので出さない
    final cap = offer != null
        ? offer.capYen
        : (isMissing && !hasResolvedCap && missingCount == 1)
        ? deal.capYen
        : null;
    // ランクの前提は**松屋ポイント側の要素にだけ**付ける
    final onRank = offer != null
        ? offer.rateMultiplier != null
        : part.brand == null;

    final notes = <String>[
      if (cap != null) t.couponCapOnlyNote(t.couponYen(formatNumber(cap))),
      if (onRank && basePercent != null)
        t.couponRankAssumeNote(
          _pick(t.couponRankNames, deal.rank),
          formatPercent(basePercent),
        ),
    ];

    parts.add(
      BestDealPartView(
        label: offer != null
            ? offerName(offer, t, tagLabels)
            : (brandLabel ?? t.couponMatsuyaPoint),
        percent: part.percent,
        iconKey: offer != null
            ? offerIconKey(offer)
            : part.brand != null
            ? brandIconKey(part.brand!)
            : cdnIconKey('matsuya'),
        noteText: notes.isEmpty ? null : notes.join(' / '),
      ),
    );
  }

  final target = deal.targetSpendYen;
  return BestDealView(
    parts: parts,
    totalPercent: deal.totalPercent,
    targetText: (deal.capYen == null || target == null)
        ? null
        : t.couponTargetNote(t.couponYen(formatNumber(target))),
    targetSpendYen: target,
    patterns: [
      for (final p in deal.patterns)
        BestDealPatternView(
          items: [
            for (final item in p.items)
              BestDealItemView(
                name: item.name,
                priceYen: item.priceYen,
                articleSlug:
                    item.articleSlug != null && slugs.contains(item.articleSlug)
                    ? item.articleSlug
                    : null,
                thumbnail: item.thumbnail,
              ),
          ],
          totalYen: p.totalYen,
          backYen: p.backYen,
          netYen: p.netYen,
        ),
    ],
  );
}

String _pick(Map<String, String> table, String key) => table[key] ?? key;
