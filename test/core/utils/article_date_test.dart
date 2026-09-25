import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/utils/article_date.dart';

void main() {
  final now = DateTime.utc(2026, 9, 25, 12);
  String rel(Duration ago, AppLocale locale) => withClock(
    Clock.fixed(now),
    () => formatRelativeDate(now.subtract(ago), locale),
  );

  test('web の relativeFromNow と同じしきい値（素直な切り捨て）', () {
    expect(rel(const Duration(seconds: 59), AppLocale.ja), 'たった今');
    expect(rel(const Duration(minutes: 1), AppLocale.ja), '1分前');
    expect(rel(const Duration(minutes: 59), AppLocale.ja), '59分前');
    expect(rel(const Duration(hours: 23, minutes: 59), AppLocale.ja), '23時間前');
    // dayjs なら「1日前」が 35 時間まで続くが、とん速の web は 24 時間で切る
    expect(rel(const Duration(hours: 47), AppLocale.ja), '1日前');
    expect(rel(const Duration(days: 29), AppLocale.ja), '29日前');
    expect(rel(const Duration(days: 30), AppLocale.ja), '1ヶ月前');
    expect(rel(const Duration(days: 365), AppLocale.ja), '1年前');
  });

  test('未来の日時は「たった今」に丸める', () {
    expect(rel(const Duration(hours: -3), AppLocale.ja), 'たった今');
  });

  test('英語は複数形、中国語は単位の語が違う', () {
    expect(rel(const Duration(hours: 1), AppLocale.en), '1 hour ago');
    expect(rel(const Duration(hours: 2), AppLocale.en), '2 hours ago');
    expect(rel(const Duration(seconds: 5), AppLocale.en), 'just now');
    expect(rel(const Duration(minutes: 3), AppLocale.zh), '3分钟前');
    expect(rel(const Duration(days: 2), AppLocale.zh), '2天前');
  });

  test('絶対表記は Asia/Tokyo（web の formatDateTime / formatDateOnly）', () {
    // UTC 15:30 は JST の翌日 0:30
    final t = DateTime.utc(2026, 9, 24, 15, 30);
    expect(formatArticleDateTime(t, AppLocale.ja), '2026年9月25日 00:30');
    expect(formatArticleDateTime(t, AppLocale.en), 'Sep 25, 2026 00:30');
    expect(formatDateOnly(t, AppLocale.zh), '2026年9月25日');
  });
}
