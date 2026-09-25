import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/calendar/domain/calendar_grid.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

/// **端末の時刻設定に左右されないこと。** 日付を端末のローカル時刻で読むと、
/// 夏時間の切り替えをまたいだ週で日数を 1 日少なく数え、線と印が 1 列ずれる
/// （PR #22 のレビューで、シドニーの時刻設定・本番の 10 月の予定で再現）。
///
/// **このテストは CI で `TZ=Australia/Sydney` でも回す**（`.github/workflows/ci.yml`）。
/// 日本時間や UTC で回しただけでは、ずれが起きないので何も見ていない。
/// シドニーは 2026-10-04（日）の 2 時に夏時間へ切り替わる。
void main() {
  CalendarEvent event(String id, String start, [String? end]) => CalendarEvent(
    id: id,
    title: id,
    category: 'store',
    startDate: start,
    endDate: end,
  );

  // 2026-10-04（日）〜 10-10（土）
  final week = monthWeeks('2026-10').firstWhere((w) => w.first == '2026-10-04');
  const today = '2026-09-25';

  test('夏時間をまたぐ週でも、期間の線は終わりの日まで引く', () {
    final layout = layoutWeek(
      week,
      [event('temp-close', '2026-10-04', '2026-10-09')],
      'store',
      today,
    );
    final segment = layout.segments.single;
    expect(segment.colStart, 0, reason: '日曜から');
    expect(segment.colEnd, 5, reason: '金曜まで（1 日手前で終わっていた）');
  });

  test('夏時間をまたぐ週でも、印はその日の列に出る', () {
    final layout = layoutWeek(
      week,
      [event('open', '2026-10-10')],
      'store',
      today,
    );
    expect(layout.segments.single.colStart, 6, reason: '土曜（金曜に出ていた）');
  });
}
