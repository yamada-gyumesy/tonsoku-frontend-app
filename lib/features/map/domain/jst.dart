/// マップの配信データの時刻（JST）を読む・出す。
///
/// **配信の時刻はすべて日本時間の壁時計**（`YYYY-MM-DD HH:mm`、日付だけのものは
/// `YYYY-MM-DD`）で、タイムゾーンの印を持たない。
///
/// **`DateTime.parse` にそのまま渡さないこと。** 印の無い文字列は端末の
/// タイムゾーンで読まれるので、海外の端末では発売・終売・開店の時刻が
/// 時差ぶんずれる（牛めしレーダーは `DateTime.parse` をそのまま使っており、
/// 端末が日本にある前提で書かれている）。ここで UTC の瞬間に直してから比べる。
/// 画面に出す時も JST に戻して出す（記事の日付と同じ。`article_date.dart`）。
library;

const _jst = Duration(hours: 9);

final _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2}))?$');

/// JST の時刻を読んで UTC の瞬間にする。**日付だけならその日の 0:00（JST）**。
/// 読めなければ null（配信の形が崩れても画面ごと落とさない）。
DateTime? parseJst(String? value) {
  if (value == null) return null;
  final m = _pattern.firstMatch(value.trim());
  if (m == null) return null;
  final wall = DateTime.utc(
    int.parse(m[1]!),
    int.parse(m[2]!),
    int.parse(m[3]!),
    int.parse(m[4] ?? '0'),
    int.parse(m[5] ?? '0'),
  );
  return wall.subtract(_jst);
}

/// 時刻を持たない（日付だけの）値か。**終売の時刻が分からない品**は日付だけで来る
/// （`app/limited.json` の `ended_at`）。
bool isDateOnly(String value) => !value.trim().contains(RegExp('[ T]'));

/// UTC の瞬間を JST の壁時計に戻す（表示用）。
DateTime toJstWall(DateTime instant) => instant.toUtc().add(_jst);
