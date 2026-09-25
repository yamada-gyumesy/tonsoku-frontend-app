import 'package:clock/clock.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';

/// 記事の日付表示。
///
/// **web（`src/utils/date.ts` / `src/utils/relative-time.ts`）と同じ結果を出すことが
/// 要件。** 同じ記事をアプリと web で見た時に日付が食い違うと、どちらかが古いように
/// 見える。
///
/// ## 常に Asia/Tokyo で出す
///
/// 端末のタイムゾーンに合わせない。扱っている出来事（新メニューの発売日・店舗の
/// 開店時刻）がすべて日本時間で決まっているので、海外の端末で見た時に前日に
/// ずれると意味が変わる。web も `dayjs.tz('Asia/Tokyo')` で固定している。
const _jst = Duration(hours: 9);

DateTime _toJst(DateTime dateTime) => dateTime.toUtc().add(_jst);

String _two(int v) => v.toString().padLeft(2, '0');

/// 今日（Asia/Tokyo）の `YYYY-MM-DD`。
///
/// **配信データの日付は JST の日付で来る**ので、突き合わせる側も JST で持つ。
/// 端末のタイムゾーンで数えると、日付をまたぐ前後で今日が前日・翌日にずれる。
String todayInJst() => dateInJst(clock.now());

/// その時刻の Asia/Tokyo の暦日（`YYYY-MM-DD`）。
///
/// **記事の掲載日を配信の日付（予定の `start_date` など）と突き合わせる時に使う。**
/// 記事の見出しに出す日時（[formatArticleDateTime]）と同じ日になる。
String dateInJst(DateTime dateTime) {
  final t = _toJst(dateTime);
  return '${t.year.toString().padLeft(4, '0')}-${_two(t.month)}-${_two(t.day)}';
}

/// 相対表記（「3時間前」）。**web の `relativeFromNow` をそのまま移してある。**
///
/// **gyumesy-frontend-app の実装（dayjs の `relativeTime` の写し）を持ち込まないこと。**
/// とん速の web は dayjs を使わず自前で書いていて（クライアントへ送る重さと、
/// `Intl` の ICU の版による揺れを避けるため）、**しきい値も文言も違う**:
///
/// - 単位の境目は素直な切り捨て（60 秒・60 分・24 時間・30 日・365 日）。
///   dayjs の「35 時間までは 1 日」「45 日までは 1ヶ月」のような丸めは無い
/// - 1 分未満は「たった今」。**未来の日時もここに入る**（配信の時計がずれた時に
///   「-3時間前」を出しても読む人が困るだけ、という web の判断）
String formatRelativeDate(DateTime dateTime, AppLocale locale) {
  final elapsed =
      clock.now().toUtc().difference(dateTime.toUtc()).inMicroseconds /
      Duration.microsecondsPerSecond;
  if (elapsed < 60) return _just(locale);
  for (final (limit, perUnit, unit) in _divisions) {
    if (elapsed < limit) return _ago((elapsed / perUnit).floor(), unit, locale);
  }
  return '';
}

enum _Unit { second, minute, hour, day, month, year }

/// `[この単位で表す上限（秒）, 1単位あたりの秒数, 単位]`。web の `DIVISIONS`。
const _divisions = <(double, int, _Unit)>[
  (60, 1, _Unit.second),
  (60 * 60, 60, _Unit.minute),
  (60 * 60 * 24, 60 * 60, _Unit.hour),
  (60 * 60 * 24 * 30, 60 * 60 * 24, _Unit.day),
  (60 * 60 * 24 * 365, 60 * 60 * 24 * 30, _Unit.month),
  (double.infinity, 60 * 60 * 24 * 365, _Unit.year),
];

String _just(AppLocale locale) => switch (locale) {
  AppLocale.ja => 'たった今',
  AppLocale.en => 'just now',
  AppLocale.zh => '刚刚',
};

/// **英語は複数形が要る**（`1 hour ago` / `2 hours ago`）。日本語・中国語は
/// 数に応じた語形変化が無い（web の `TEXTS`）。
String _ago(int n, _Unit unit, AppLocale locale) => switch (locale) {
  AppLocale.ja =>
    '$n${switch (unit) {
      _Unit.second => '秒',
      _Unit.minute => '分',
      _Unit.hour => '時間',
      _Unit.day => '日',
      _Unit.month => 'ヶ月',
      _Unit.year => '年',
    }}前',
  AppLocale.en => '$n ${unit.name}${n == 1 ? '' : 's'} ago',
  AppLocale.zh =>
    '$n${switch (unit) {
      _Unit.second => '秒',
      _Unit.minute => '分钟',
      _Unit.hour => '小时',
      _Unit.day => '天',
      _Unit.month => '个月',
      _Unit.year => '年',
    }}前',
};

const _enMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// 日付だけ（`2026年9月25日` / `Sep 25, 2026`）。web の `formatDateOnly`。
String formatDateOnly(DateTime dateTime, AppLocale locale) {
  final t = _toJst(dateTime);
  return switch (locale) {
    AppLocale.ja || AppLocale.zh => '${t.year}年${t.month}月${t.day}日',
    AppLocale.en => '${_enMonths[t.month - 1]} ${t.day}, ${t.year}',
  };
}

/// 記事詳細に出す絶対表記（`2026年9月25日 14:05`）。web の `formatDateTime`。
String formatArticleDateTime(DateTime dateTime, AppLocale locale) {
  final t = _toJst(dateTime);
  final time = '${_two(t.hour)}:${_two(t.minute)}';
  return switch (locale) {
    AppLocale.ja || AppLocale.zh => '${t.year}年${t.month}月${t.day}日 $time',
    AppLocale.en => '${_enMonths[t.month - 1]} ${t.day}, ${t.year} $time',
  };
}

/// 年を落とした日付（`9/23` / `Sep 23`）。web の `formatMonthDay`。
///
/// **`en` だけ `MMM D`**。`9/23` は英語話者には `MM/DD` とも `DD/MM` とも読めるので、
/// 日付の意味そのものが変わって伝わる（gyumesy と同じ判断）。
///
/// 引数は配信の `2026-09-23` の形の文字列。**`DateTime` を経由しない** ——
/// 配信は日付だけを持つので、変換するとタイムゾーンのぶん前日・翌日にずれる
/// 余地が生まれる。**形か範囲が壊れていたらそのまま返す**（gyumesy が
/// 「英語で開いている人だけ画面が落ちる」を踏んでいる）。
String formatMonthDay(String isoDate, AppLocale locale) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || day == null) return isoDate;
  if (month < 1 || month > 12) return isoDate;

  return switch (locale) {
    AppLocale.ja || AppLocale.zh => '$month/$day',
    AppLocale.en => '${_enMonths[month - 1]} $day',
  };
}

/// 年を落とした日時（`9/30 15:00` / `Sep 30 15:00`）。web の `formatMonthDayTime`。
/// クーポンの終了時刻に使う（**Asia/Tokyo**）。
String formatMonthDayTime(DateTime dateTime, AppLocale locale) {
  final t = _toJst(dateTime);
  final time = '${_two(t.hour)}:${_two(t.minute)}';
  return switch (locale) {
    AppLocale.ja || AppLocale.zh => '${t.month}/${t.day} $time',
    AppLocale.en => '${_enMonths[t.month - 1]} ${t.day} $time',
  };
}
