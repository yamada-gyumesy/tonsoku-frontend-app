import 'package:flutter/material.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/coupon/domain/coupon_schedule.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';

// **寸法はここ 1 箇所だけに置く。** 今日の縦線がこの合計ぶん右にずれた位置に
// 立つので、描画側にも同じ数字を書くと**片方を広げた時に線だけがずれる**
// （ビルドも lint も通るので気づけない）。web も同じ断りを CSS に書いている。
const _iconWidth = 24.0;
const _nameWidth = 88.0;
const _columnGap = 8.0;

/// トラックの左端（アイコン + すき間 + 名前 + すき間）。
const _trackLeft = _iconWidth + _columnGap + _nameWidth + _columnGap;

/// 行の高さ。**縮めると日付が帯に重なる**（9px の字 + すき間 2px +
/// 帯の半分 = 中央から 14.2px）。
const _trackHeight = 32.0;

/// 帯の太さ。web の `--bar-h: 0.4rem`。
const _barHeight = 6.4;

/// 今日の線の上下に付ける横棒の幅（大文字の I の上下の棒）。
const _todayCapWidth = 9.0;

/// 線の太さ。**縦線と上下の棒で共通**（片方だけ変えると I が歪む）。
const _todayStroke = 1.0;

/// 足元の日付を置くぶんの高さ。web の `--today-label-h: 0.875rem`。
///
/// **字の高さ（9px）より広い。** 差の 5px がそのまま**線の下端と日付の間の
/// すき間**になる（日付はこの枠の下端に置く。`_CenterAt`）。web も同じで、
/// 線が `bottom: var(--today-label-h)` で止まり、日付が `bottom: 0` に付く。
const _todayLabelHeight = 14.0;

/// スケジュールの帯。web の `CoCouponSchedule`。
///
/// **いつまで使えて、次に何が始まるか**を帯で出す。一覧では「〜9/12」としか
/// 分からない前後関係（今週で終わる／入れ替わりで始まる）が、ここで一目になる。
/// **競合の一覧サイトはどこも持っていない。**
class CouponScheduleChart extends StatelessWidget {
  const CouponScheduleChart({required this.schedule, super.key});
  final CouponSchedule schedule;
  @override
  Widget build(BuildContext context) {
    if (schedule.bars.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth - _trackLeft;
        // **今日の線と足元の日付が立つ位置。2 箇所で使うので式はここ 1 つ**
        // （書き写すと、片方だけ直した時に線と日付が別の日を指す）
        final todayX = _trackLeft + trackWidth * schedule.todayPercent / 100;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: _todayLabelHeight),
              child: Column(
                children: [
                  for (final bar in schedule.bars)
                    _BarRow(bar: bar, trackWidth: trackWidth),
                ],
              ),
            ),
            // **今日の縦線は行をまたぐ 1 本。** 行ごとに引くと点線が並んで見え、
            // どこが今日なのか分からなくなる
            Positioned(
              left: todayX - _todayCapWidth / 2,
              top: 0,
              bottom: _todayLabelHeight,
              width: _todayCapWidth,
              child: const _TodayLine(),
            ),
            // 線の足元の日付。**線は薄く、こちらは薄めない**（線が何かを明かす役）
            // **高さを与える。** `CustomSingleChildLayout` は親の制約を
            // そのまま子へ渡すので、`Positioned(left/right/bottom)` だけだと
            // 高さが無限になって落ちる（テストで出した）
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _todayLabelHeight,
              child: _TodayLabel(x: todayX, text: schedule.todayLabel),
            ),
          ],
        );
      },
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.bar, required this.trackWidth});
  final CouponScheduleBar bar;
  final double trackWidth;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // **絵が無い行も同じ幅を空ける**（web の空の `schedule-icon`）。
          // 詰めると名前の列が行ごとにずれ、今日の線とトラックの左端が合わなくなる
          SizedBox(
            width: _iconWidth,
            height: _iconWidth,
            child: bar.iconKey == null
                ? null
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CdnImage(
                      url: bar.iconKey!,
                      width: _iconWidth,
                      height: _iconWidth,
                    ),
                  ),
          ),
          const SizedBox(width: _columnGap),
          SizedBox(
            width: _nameWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bar.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: FontWeight.bold,
                    color: colors.text,
                  ),
                ),
                // **帯だけだと「いつ」しか分からず、どれを優先するかは決められない**
                if (bar.value != null)
                  Text(
                    bar.value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      color: colors.textSub,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: _columnGap),
          Expanded(
            child: SizedBox(
              height: _trackHeight,
              child: _Track(bar: bar, trackWidth: trackWidth),
            ),
          ),
        ],
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.bar, required this.trackWidth});
  final CouponScheduleBar bar;
  final double trackWidth;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const barTop = (_trackHeight - _barHeight) / 2;
    final left = trackWidth * bar.left / 100;
    final width = trackWidth * bar.width / 100;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // **帯の地は帯と同じ高さに敷く**（トラック全面に敷くと線に見えない）
        Positioned(
          top: barTop,
          left: 0,
          right: 0,
          height: _barHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.text.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        Positioned(
          top: barTop,
          left: left,
          width: width,
          height: _barHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // **今使えるものは `primaryText`、これから始まるものは `green` の
              // 薄塗り。** 色相で分ける（濃淡だけだとどちらも同じ強さに見える）。
              // **枠線にしないこと** —— この太さでは中身がほとんど残らず
              // 小さな輪に見える。**塗りの `primary` にしない**（地の上に直接
              // 置く線なので、ダークで 3:1 に届かない。`AppColors.primary`）
              color: bar.upcoming
                  ? colors.green.withValues(alpha: 0.55)
                  : colors.primaryText,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        // 日付は**帯の意味のある端**に揃える（開催中＝終了日なので右端、
        // 予定＝開始日なので左端）。**トラックからはみ出す時は反対の端で止める** ——
        // 判定は `_placeLabel`（実測で `From Sep 17` が器を 79pt はみ出した）
        Positioned(
          bottom: barTop + _barHeight + 2,
          left: bar.labelAlign == LabelAlign.start
              ? trackWidth * bar.labelOffset / 100
              : null,
          right: bar.labelAlign == LabelAlign.end
              ? trackWidth * bar.labelOffset / 100
              : null,
          child: Text(
            bar.label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 9,
              height: 1,
              // 文字は帯と同じ色相。**薄めない**
              color: bar.upcoming ? colors.green : colors.primaryText,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

/// 今日の縦線。**大文字の I のかたち**（縦線＋上下の短い横棒）。
///
/// 素の縦線 1 本だと帯の上を横切る別の帯に見えて不具合のように読める。
/// **丸ポチにしないこと** —— 帯の端が角丸なので語彙が重なり、上端の丸が
/// 最上行の帯の左端に見える。横棒は帯と直交するぶん混ざらない。
///
/// **色は `primaryText`。** ニュートラルにしないこと —— 灰色は「終了・無効」の
/// 記号に読め、薄く塗った予定の帯と意味が重なって不具合に見える。
/// **`green` にもしない**（予定の帯と同じ色になり色の意味が濁る）。
/// **`primarySoft` も使わない**（地に敷くための色で、線にするとライトでほぼ消える）。
class _TodayLine extends StatelessWidget {
  const _TodayLine();
  @override
  Widget build(BuildContext context) {
    // **1px / 不透明度 0.5。** 太く引くと線ではなく淡い面に見え、帯と重なった
    // ときに不具合のように読める。逆に濃くしすぎない（今日を目立たせるのが
    // 目的ではない）。0.28 まで薄めると上下の棒が消えかける
    final color = context.colors.primaryText.withValues(alpha: 0.5);
    return Stack(
      children: [
        // **縦線は器いっぱいに伸ばす。** `Align` + `SizedBox(width:)` だと
        // `ColoredBox` に子が無いぶん高さが 0 になり、上下の棒しか残らない
        // （実機でそれを出した）
        Positioned(
          left: (_todayCapWidth - _todayStroke) / 2,
          top: 0,
          bottom: 0,
          width: _todayStroke,
          child: ColoredBox(color: color),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: _todayStroke,
          child: ColoredBox(color: color),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _todayStroke,
          child: ColoredBox(color: color),
        ),
      ],
    );
  }
}

class _TodayLabel extends StatelessWidget {
  const _TodayLabel({required this.x, required this.text});
  final double x;
  final String text;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomSingleChildLayout(
      delegate: _CenterAt(x),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          height: 1,
          color: colors.primaryText,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// [x] を中心に置く（web の `translateX(-50%)`）。
class _CenterAt extends SingleChildLayoutDelegate {
  const _CenterAt(this.x);
  final double x;
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      // **緩めるだけでは足りない。** 親が高さ無限だとそのまま渡ってしまうので、
      // 子は自分の欲しい大きさを取れる形（完全に自由）にする
      const BoxConstraints();
  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      // **枠の下端に置く。** 上端に置くと線の下端にくっついて読みにくい
      // （実機で指摘）。web は日付を `bottom: 0` に付けているので、
      // 枠の高さ（[_todayLabelHeight]）と字の高さの差がすき間になる
      Offset(x - childSize.width / 2, size.height - childSize.height);
  @override
  bool shouldRelayout(_CenterAt oldDelegate) => oldDelegate.x != x;
}

/// スケジュールの帯の日付ラベルの幅（トラック幅に対する %）。
///
/// **web は 9px の文字幅を定数で見積もっている**（`LABEL_CHAR_PX`）が、それは
/// SSG で測れないから。**アプリは `TextPainter` で実寸が取れるので測る。**
///
/// 見積もりは少なく見ると「収まらないのに収まる」と判定して外へ出し、
/// 多く見ると「収まるのにはみ出す」と判定して帯と日付の端が揃わなくなる。
double measureScheduleLabel(String label, {required double trackWidth}) {
  if (trackWidth <= 0) return 0;
  final painter = TextPainter(
    text: TextSpan(text: label, style: const TextStyle(fontSize: 9, height: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width / trackWidth * 100;
}

/// トラックの幅（アイコン・名前・すき間を引いたぶん）。
double scheduleTrackWidth(double available) => available - _trackLeft;
