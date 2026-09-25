import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/calendar/domain/calendar_window.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

CalendarEvent event({
  required String start,
  String? end,
  bool ongoing = false,
  String id = 'e',
  String title = 't',
  String category = 'menu',
}) => CalendarEvent(
  id: id,
  title: title,
  category: category,
  startDate: start,
  endDate: end,
  ongoing: ongoing,
);

void main() {
  group('期間の表示', () {
    test('単日は開始日だけ', () {
      expect(event(start: '2026-08-25').period, '8/25');
      expect(event(start: '2026-08-25', end: '2026-08-25').period, '8/25');
      expect(event(start: '2026-08-25').hasPeriod, isFalse);
    });

    test('期間があれば範囲で出す', () {
      final e = event(start: '2026-08-25', end: '2026-09-01');
      expect(e.period, '8/25〜9/1');
      expect(e.hasPeriod, isTrue);
    });

    test('先頭の 0 を落とす', () {
      expect(event(start: '2026-01-05', end: '2026-02-09').period, '1/5〜2/9');
    });
  });

  group('coversDate', () {
    test('開始前は含まない', () {
      expect(event(start: '2026-08-25').coversDate('2026-08-24'), isFalse);
    });

    test('終了日を含む', () {
      final e = event(start: '2026-08-25', end: '2026-08-27');
      expect(e.coversDate('2026-08-27'), isTrue);
      expect(e.coversDate('2026-08-28'), isFalse);
    });

    test('終わりが決まっていない継続中は開始日以降ずっと', () {
      final e = event(start: '2025-03-17', ongoing: true);
      expect(e.coversDate('2026-08-23'), isTrue);
    });
  });

  group('その日にかかる予定（日タップ）', () {
    // 一覧の行には開始日がその日の予定しか並ばないので、通過中の予定は
    // ここでしか見えない
    const today = '2026-08-24';
    final events = [
      event(start: '2026-08-20', end: '2026-08-27', id: '期間中'),
      event(start: '2026-08-24', id: '当日開始'),
      event(start: '2026-02-01', ongoing: true, id: '継続中'),
      event(start: '2026-08-25', id: '翌日開始'),
      event(start: '2026-08-01', end: '2026-08-10', id: '終了済み'),
      event(start: '2026-08-10', id: '定番'),
    ];

    List<String> onDay(String date) => [
      for (final e in eventsOnDay(events, date, today)) e.id,
    ];

    test('開始日が同じものだけでなく期間中の予定も含む', () {
      expect(onDay('2026-08-24'), containsAll(['期間中', '当日開始', '継続中']));
    });

    test('未来と終了済みは含まない', () {
      expect(onDay('2026-08-24'), isNot(contains('翌日開始')));
      expect(onDay('2026-08-24'), isNot(contains('終了済み')));
    });

    test('終わりが決まっていない継続中は今日まで伸びる', () {
      // 今日（8/24）は含み、明日は含まない
      expect(onDay('2026-08-24'), contains('継続中'));
      expect(onDay('2026-08-25'), isNot(contains('継続中')));
    });

    /// **終わりも継続も無い予定は点**（定番。配信側の契約）。開始日の後の日に
    /// 出すと、定番がずっと「その日の予定」に並ぶ。
    test('定番（終わり無し・継続でもない）は開始日だけ', () {
      expect(onDay('2026-08-10'), contains('定番'));
      expect(onDay('2026-08-11'), isNot(contains('定番')));
    });

    /// **まだ始まっていない継続中は線にならない**（web の `eventsOnDay` は
    /// `hasSpan` で見る）。開始日にだけ出る。
    test('まだ始まっていない継続中は開始日だけ', () {
      final future = [event(start: '2026-08-30', ongoing: true, id: '予告')];
      expect(eventsOnDay(future, '2026-08-30', today).map((e) => e.id), ['予告']);
      expect(eventsOnDay(future, '2026-08-31', today), isEmpty);
    });

    test('カテゴリの優先度で並ぶ', () {
      final mixed = [
        event(start: '2026-08-24', id: 'campaign', category: 'campaign'),
        event(start: '2026-08-24', id: 'menu'),
        event(start: '2026-08-24', id: 'store', category: 'store'),
        event(start: '2026-08-24', id: 'official', category: 'official'),
      ];
      expect(eventsOnDay(mixed, '2026-08-24', today).map((e) => e.id), [
        'menu',
        'official',
        'store',
        'campaign',
      ]);
    });
  });

  group('日リストの行', () {
    /// **優先度 → 題で並べる**（web の `buildDayList`。gyumesy は配信の順）。
    test('同じ日の予定は優先度 → 題の順', () {
      final events = [
        event(start: '2026-09-09', id: 'c2', title: 'B', category: 'campaign'),
        event(start: '2026-09-09', id: 'm2', title: 'B'),
        event(start: '2026-09-09', id: 'c1', title: 'A', category: 'campaign'),
        event(start: '2026-09-09', id: 'm1', title: 'A'),
      ];
      expect(dayEntries(events, '2026-09-09').map((e) => e.id), [
        'm1',
        'm2',
        'c1',
        'c2',
      ]);
    });

    test('月の全日を出し、予定が無い日も行として残す', () {
      final days = buildMonthDays(
        [event(start: '2026-09-10', end: '2026-09-20', id: 'x')],
        '2026-09',
        '2026-09-25',
      );
      expect(days, hasLength(30));
      expect(days.first.date, '2026-09-01');
      // 2026-09-01 は火曜（日曜=0）
      expect(days.first.weekday, 2);
      // **行は開始日だけ**（期間の途中は線で示す）
      expect(days[9].events.map((e) => e.id), ['x']);
      expect(days[10].events, isEmpty);
      expect(days[24].isToday, isTrue);
    });
  });

  group('月の範囲', () {
    const today = '2026-09-25';

    test('予定の開始月・終了月と今月を畳み込む', () {
      final range = calendarMonthRange([
        event(start: '2026-09-10', end: '2026-11-05'),
      ], today);
      expect(range, (min: '2026-09', max: '2026-11'));
    });

    /// **収集開始（2026-09）より前へは遡らせない**（web の
    /// `CALENDAR_MONTH_FLOOR`。初回一括取り込みの開始日は信用できない）。
    test('下限より前の予定があっても下限まで', () {
      final range = calendarMonthRange([event(start: '2026-03-17')], today);
      expect(range.min, calendarMonthFloor);
    });

    /// **遠い終了日が 1 件あっても、今月から 3 ヶ月先まで**
    /// （web の `CALENDAR_MONTHS_AHEAD`）。
    test('上限は今月から 3 ヶ月先', () {
      final range = calendarMonthRange([
        event(start: '2026-09-01', end: '2030-12-31'),
      ], today);
      expect(range.max, '2026-12');
    });

    /// web: 逆転したままだと月が 1 つも出ない。**床の月を出すほうがよい。**
    test('下限が上限を超えたら下限の月だけ', () {
      final range = calendarMonthRange(const [], '2026-03-10');
      expect(range, (min: '2026-09', max: '2026-09'));
    });

    test('最初に出す月は範囲の端へ寄せる', () {
      const range = (min: '2026-09', max: '2026-11');
      expect(initialCalendarMonth(range, '2026-08-31'), '2026-09');
      expect(initialCalendarMonth(range, '2026-10-01'), '2026-10');
      expect(initialCalendarMonth(range, '2027-02-01'), '2026-11');
    });

    test('月を足すと年をまたぐ', () {
      expect(addMonths('2026-11', 3), '2027-02');
      expect(addMonths('2026-01', -1), '2025-12');
    });

    /// **メニューの行はこれで出し分ける**（web の `hasEvents`）。件数ではなく、
    /// 行ける月に行になる予定があるかで見る。
    test('行ける月に予定があるか', () {
      expect(hasCalendarEventsInRange(const [], today), isFalse);
      expect(
        hasCalendarEventsInRange([event(start: '2026-10-01')], today),
        isTrue,
      );
      // 下限より前・上限より先にしか無い
      expect(
        hasCalendarEventsInRange([
          event(start: '2026-08-31'),
          event(start: '2027-05-01'),
        ], today),
        isFalse,
      );
    });
  });

  group('記事の無くなった予定', () {
    ArticleMeta article(String slug) =>
        ArticleMeta(slug: slug, title: slug, createdAt: DateTime.utc(2026, 9));

    final events = [
      event(start: '2026-09-01', id: 'alive').copyWith(articleSlug: 'aaa'),
      event(start: '2026-09-01', id: 'gone').copyWith(articleSlug: 'zzz'),
      event(start: '2026-09-01', id: 'none'),
    ];

    /// **記事が消えても予定は残る**（web の `buildCalendarPayload` の
    /// `articleSlugs`）。リンクだけを外し、予定そのものは出す。
    test('一覧に無い slug はリンクを外す', () {
      final result = withKnownArticles(events, [article('aaa')]);
      expect(result.map((e) => e.articleSlug), ['aaa', null, null]);
      expect(result, hasLength(3));
    });

    test('一覧が届く前は外さない', () {
      expect(withKnownArticles(events, null), same(events));
    });
  });
}
