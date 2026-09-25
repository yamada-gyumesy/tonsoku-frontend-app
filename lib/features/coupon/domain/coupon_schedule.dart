import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/features/coupon/domain/coupon_row.dart';
import 'package:tonsoku/shared/models/coupon.dart';

/// スケジュールの帯 1 本。
class CouponScheduleBar {
  const CouponScheduleBar({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.value,
    required this.upcoming,
    required this.left,
    required this.width,
    required this.label,
    required this.labelAlign,
    required this.labelOffset,
  });

  final String id;
  final String name;

  /// CDN のアイコンのキー。置いていなければ null（絵を出さない）。
  final String? iconKey;

  /// 還元の値（`15%` / `70円引き`）。**帯だけだと「いつ」しか分からず、
  /// どれを優先するかを決められない**ので名前の下に小さく出す。無ければ null。
  final String? value;

  /// これから始まるぶんか。**色相で「今使える」と「まだ使えない」を分ける**
  /// （濃淡だけで分けると、どちらも同じ強さに見えて読み分けられない）。
  final bool upcoming;

  /// 窓に対する開始位置（%）。
  final double left;

  /// 窓に対する長さ（%）。
  final double width;

  /// 日付ラベル（`〜8/31` / `9/5〜` / 終了未定）。
  final String label;

  /// ラベルをどちらの端から測るか。
  final LabelAlign labelAlign;

  /// [labelAlign] の側の端からの距離（%）。
  final double labelOffset;
}

/// 日付ラベルの横位置。
///
/// ラベルは**帯の上**に置くので、幅の制約を受けるのは帯ではなく**トラック**。
/// 帯の意味のある端（開催中＝終了日なので右端、予定＝開始日なので左端）に
/// 揃えたうえで、**そのままだとトラックからはみ出す時だけ反対側の端で止める**。
///
/// **止めないと、窓の端まで伸びる帯でラベルがトラックの外へ出る。**
/// 実測（390pt 幅）: 英語の `From Sep 17` が器を **79pt** はみ出した。
/// web も「トラックにも祖先にも `overflow` は無いので、SP では本文の左右余白を
/// 食い潰してページが横スクロールする」と書いている。
///
/// **英語は日本語よりラベルが長いぶん該当する範囲が広い。**
enum LabelAlign {
  /// 左から [CouponScheduleBar.labelOffset]% の位置。
  start,

  /// 右から [CouponScheduleBar.labelOffset]% の位置。
  end,
}

/// 帯の一覧と、今日の縦線の位置。
class CouponSchedule {
  const CouponSchedule({
    required this.bars,
    required this.todayPercent,
    required this.todayLabel,
  });

  final List<CouponScheduleBar> bars;

  /// 窓の中での今日の位置（%）。
  final double todayPercent;

  /// 今日の縦線に添える日付。**帯の日付と同じ組み立てを通すこと** ——
  /// ここだけ別の書式にすると、同じ画面で「8/19」と「08/19」が並ぶ。
  final String todayLabel;
}

/// 帯を描く窓（今日の前後）。
const scheduleBeforeDays = 7;
const scheduleAfterDays = 35;

/// **いつまで使えて、次に何が始まるか**を 1 枚で見せる。
///
/// 一覧では「〜9/12」としか分からない前後関係（今週で終わる／入れ替わりで始まる）が、
/// 帯にすると一目になる。**競合の一覧サイトはどこも持っていない。**
///
/// 位置は組み立て時に % で確定させる。窓は今日の前後で固定し、はみ出すものは端で切る。
/// 終了未定のものは右端まで伸ばす。
///
/// 並びは**終わりが近い順**（今日いちばん急いで使うべきものが上に来る）。
CouponSchedule buildSchedule({
  required Coupon coupon,
  required AppMessages t,
  required Map<String, String> tagLabels,
  required String Function(String isoDate) formatMonthDay,
  required DateTime today,
  required double Function(String label) measureLabel,
}) {
  final ranks = sortedRanks(coupon.ranks);
  final from = _jstMidnight(
    today,
  ).subtract(const Duration(days: scheduleBeforeDays));
  const days = scheduleBeforeDays + scheduleAfterDays;
  double clamp(double v) => v < 0 ? 0 : (v > days ? days.toDouble() : v);

  final entries = <({CouponOffer offer, bool upcoming, String endKey})>[];

  for (final pair in [
    ...coupon.offers.map((o) => (offer: o, upcoming: false)),
    ...coupon.upcoming.map((o) => (offer: o, upcoming: true)),
  ]) {
    final offer = pair.offer;
    final start = _dayIndex(offer.startDate, from);
    final end = offer.endDate != null
        ? _dayIndex(offer.endDate!, from) + 1
        : days.toDouble();
    // **窓の外は帯にしない。** `clamp` は位置を潰すだけなので、窓より先に始まる
    // 予定は `left: 100% / width: 2%`（下駄）としてトラックの**右端から外へ**
    // 描かれ、外側に出した日付ラベルもさらに右へ出る。トラックにも祖先にも
    // クリップが無いと、本文の左右余白を食い潰して横スクロールになる
    if (start >= days || end <= 0) continue;
    entries.add((
      offer: offer,
      upcoming: pair.upcoming,
      endKey: offer.endDate ?? '9999-12-31',
    ));
  }

  // **終わりが近い順。** 文字列比較でよい（`YYYY-MM-DD` に揃っている）
  entries.sort((a, b) => a.endKey.compareTo(b.endKey));

  final bars = <CouponScheduleBar>[];
  for (final e in entries) {
    final offer = e.offer;
    final start = clamp(_dayIndex(offer.startDate, from));
    final end = offer.endDate != null
        ? clamp(_dayIndex(offer.endDate!, from) + 1)
        : days.toDouble();
    // **幅は 1 度だけ出す。** ラベルの横位置の判定でも使うので、式を書き写すと
    // 丸め方を変えた時に判定だけ古い式で残る
    final width = _round1((end - start) / days * 100).clamp(2.0, 100.0);
    final left = _round1(start / days * 100);

    // **これから始まるぶんは開始日だけ**（「9/5〜」）。まだ始まっていないので
    // 知りたいのは「いつから」で、開始と終了を並べると帯に収まらず外へあふれる。
    // **「〜」は落とさないこと**（日付だけだとその日限りの予定に見える）
    final label = e.upcoming
        ? t.couponStartsOn(formatMonthDay(offer.startDate))
        : offer.endDate != null
        ? t.couponUntil(formatMonthDay(offer.endDate!))
        : t.couponNoEndDate;

    final placement = _placeLabel(
      labelWidthPercent: measureLabel(label),
      left: left,
      width: width,
      upcoming: e.upcoming,
    );

    bars.add(
      CouponScheduleBar(
        id: offer.id,
        name: offerName(offer, t, tagLabels),
        iconKey: offerIconKey(offer),
        value: offerPrimary(offer, t, ranks),
        upcoming: e.upcoming,
        left: left,
        width: width,
        label: label,
        labelAlign: placement.align,
        labelOffset: placement.offset,
      ),
    );
  }

  return CouponSchedule(
    bars: bars,
    todayPercent: _round1(scheduleBeforeDays / days * 100),
    todayLabel: formatMonthDay(_iso(today)),
  );
}

/// ラベルの横位置。web の `labelPlacement()`。
///
/// **[labelWidthPercent] はトラック幅に対する割合。** web は 9px の文字幅を
/// 定数で見積もっているが（SSG で測れないため）、**アプリは `TextPainter` で
/// 実寸が取れる**。写すより測るほうが正しい —— 見積もりは少なく見ると
/// 「収まらないのに収まる」と判定して外へ出し、多く見ると「収まるのに
/// はみ出す」と判定して帯と日付の端が揃わなくなる。
({LabelAlign align, double offset}) _placeLabel({
  required double labelWidthPercent,
  required double left,
  required double width,
  required bool upcoming,
}) {
  if (upcoming) {
    // 予定は帯の**左端**（開始日）に揃える
    return left + labelWidthPercent <= 100
        ? (align: LabelAlign.start, offset: left)
        : (align: LabelAlign.end, offset: 0);
  }
  // 開催中は帯の**右端**（終了日）に揃える
  return left + width - labelWidthPercent >= 0
      ? (align: LabelAlign.end, offset: _round1(100 - (left + width)))
      : (align: LabelAlign.start, offset: 0);
}

/// 窓の先頭から数えた日数。**日付は JST の 0 時で揃える**（配信も JST の日付で持つ）。
double _dayIndex(String isoDate, DateTime from) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return 0;
  final d = DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  ).subtract(const Duration(hours: 9));
  return d.difference(from).inMilliseconds / Duration.millisecondsPerDay;
}

DateTime _jstMidnight(DateTime today) {
  final jst = today.toUtc().add(const Duration(hours: 9));
  return DateTime.utc(
    jst.year,
    jst.month,
    jst.day,
  ).subtract(const Duration(hours: 9));
}

String _iso(DateTime today) {
  final jst = today.toUtc().add(const Duration(hours: 9));
  final m = jst.month.toString().padLeft(2, '0');
  final d = jst.day.toString().padLeft(2, '0');
  return '${jst.year}-$m-$d';
}

double _round1(double v) => (v * 10).round() / 10;
