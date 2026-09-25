import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/calendar/domain/calendar_window.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

/// 記事詳細の「この記事の前後の予定」の窓（web の `CoCalendarSection` の計算）。
///
/// **このテストは CI で `TZ=Australia/Sydney` でも回る**（`test/features/calendar`
/// の下に置いてある。`.github/workflows/ci.yml`）。日を足す計算を端末の
/// ローカル時刻で行うと、夏時間の切り替え（シドニーは 2026-10-04 に始まり
/// 2027-04-04 に終わる）をまたいだ所で日付が重複したり飛んだりする。
void main() {
  CalendarEvent event(
    String id,
    String start, {
    String? end,
    bool ongoing = false,
  }) => CalendarEvent(
    id: id,
    title: id,
    category: 'menu',
    startDate: start,
    endDate: end,
    ongoing: ongoing,
  );

  group('窓の日付', () {
    test('中心日の前後 2 日の 5 日ぶん', () {
      final window = scheduleWindow(
        const [],
        center: '2026-09-25',
        today: '2026-09-25',
      );
      expect(window.dates, [
        '2026-09-23',
        '2026-09-24',
        '2026-09-25',
        '2026-09-26',
        '2026-09-27',
      ]);
    });

    test('月と年をまたぐ', () {
      expect(
        scheduleWindow(
          const [],
          center: '2026-12-31',
          today: '2026-09-25',
        ).dates,
        ['2026-12-29', '2026-12-30', '2026-12-31', '2027-01-01', '2027-01-02'],
      );
    });

    test('夏時間の始まりをまたいでも日付が重複・欠落しない', () {
      expect(
        scheduleWindow(
          const [],
          center: '2026-10-04',
          today: '2026-09-25',
        ).dates,
        ['2026-10-02', '2026-10-03', '2026-10-04', '2026-10-05', '2026-10-06'],
      );
    });

    test('夏時間の終わりをまたいでも日付が重複・欠落しない', () {
      expect(
        scheduleWindow(
          const [],
          center: '2027-04-04',
          today: '2026-09-25',
        ).dates,
        ['2027-04-02', '2027-04-03', '2027-04-04', '2027-04-05', '2027-04-06'],
      );
    });

    test('日リストの行は窓の日付と曜日で並ぶ', () {
      final window = scheduleWindow(
        [event('a', '2026-10-04')],
        center: '2026-10-04',
        today: '2026-09-25',
      );
      final days = buildDays(window.events, window.dates, window.today);
      expect([for (final d in days) d.day], [2, 3, 4, 5, 6]);
      // 2026-10-04 は日曜（0）
      expect([for (final d in days) d.weekday], [5, 6, 0, 1, 2]);
      expect(days[2].events.single.id, 'a');
    });
  });

  group('窓の「今日」', () {
    const dates = ['2026-09-23', '2026-09-24', '2026-09-25'];

    test('窓が過去なら窓の翌日で頭打ち', () {
      expect(clampTodayToWindow('2026-10-10', dates), '2026-09-26');
    });

    test('窓の中・窓より前なら実際の今日', () {
      expect(clampTodayToWindow('2026-09-24', dates), '2026-09-24');
      expect(clampTodayToWindow('2026-09-01', dates), '2026-09-01');
    });
  });

  group('窓に絞った予定', () {
    const center = '2026-09-25';
    const today = '2026-10-10';

    List<String> ids(List<CalendarEvent> events) => scheduleWindow(
      events,
      center: center,
      today: today,
    ).events.map((e) => e.id).toList();

    test('窓の中に始まる予定は残す', () {
      expect(ids([event('in', '2026-09-23'), event('edge', '2026-09-27')]), [
        'in',
        'edge',
      ]);
    });

    test('窓を通る期間の予定は残す（行は無くても日タップで出る）', () {
      expect(ids([event('through', '2026-09-01', end: '2026-09-30')]), [
        'through',
      ]);
    });

    test('継続中の予定は窓の翌日まで伸びる扱いで残す', () {
      expect(ids([event('ongoing', '2026-09-01', ongoing: true)]), ['ongoing']);
    });

    /// **節を出すかどうかはこれで決まる。** 予定はあるが窓の中には無い時に
    /// 見出しだけが出て中身が空になった（web のコメント）
    test('窓の外の予定しか無ければ空', () {
      expect(
        ids([
          event('before', '2026-09-01', end: '2026-09-22'),
          event('after', '2026-09-28'),
          event('single-before', '2026-09-22'),
        ]),
        isEmpty,
      );
    });
  });

  group('記事の掲載日', () {
    /// 配信の `created_at` は `+00:00`。JST の 0〜9 時に出た記事は UTC だと前日
    test('JST の暦日で取る', () {
      expect(
        dateInJst(DateTime.parse('2026-09-24T20:00:00+00:00')),
        '2026-09-25',
      );
      expect(
        dateInJst(DateTime.parse('2026-09-24T14:59:59+00:00')),
        '2026-09-24',
      );
    });
  });
}
