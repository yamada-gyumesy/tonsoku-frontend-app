/// クーポンの数値の整形。web の `coupon.ts` の `formatPercent` / `formatNumber`。
library;

/// 小数第 1 位で丸め、小数点以下が 0 の時は落とす（`15.0%` ではなく `15%`）。
///
/// **とん速の web は丸めてから出す**（`Math.round(value * 10) / 10`）。gyumesy の
/// アプリは丸めずに出していたので、倍率 × 付与率の幅（`12.600000000000001%`）が
/// そのまま出うる。
String formatPercent(double value) {
  final rounded = (value * 10).round() / 10;
  final s = rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toString();
  return '$s%';
}

/// 3 桁区切り。`1334` → `1,334`。
String formatNumber(num value) {
  final s = value.round().abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
