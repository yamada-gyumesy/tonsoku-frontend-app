import 'package:flutter_test/flutter_test.dart';

import 'package:tonsoku/features/calendar/domain/calendar_window.dart';
import 'package:tonsoku/features/calendar/domain/day_lanes.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

/// 日リストの縦線。**行は開始日しか作らないので、期間予定は線で日をまたぐ。**
/// 線が無いと単日の予定と区別できない（web の `buildDayList`）。
void main() {
  const today = '2026-08-24';
  const dates = [
    '2026-08-22',
    '2026-08-23',
    '2026-08-24',
    '2026-08-25',
    '2026-08-26',
  ];

  CalendarEvent event({
    required String id,
    required String start,
    String? end,
    String category = 'menu',
    bool ongoing = false,
    String? title,
  }) => CalendarEvent(
    id: id,
    title: title ?? id,
    category: category,
    startDate: start,
    endDate: end,
    ongoing: ongoing,
  );

  test('カテゴリを選んでいない時は線を引かない', () {
    final lanes = buildDayLanes(
      [event(id: 'a', start: '2026-08-22', end: '2026-08-26')],
      dates,
      today,
      category: null,
    );
    expect(lanes.laneCount, 0);
    for (final d in dates) {
      expect(lanes.linesOn(d), isEmpty);
    }
  });

  test('期間予定は始まりから終わりまで毎日 1 本通る', () {
    final lanes = buildDayLanes(
      [event(id: 'a', start: '2026-08-23', end: '2026-08-25')],
      dates,
      today,
      category: 'menu',
    );

    expect(lanes.laneCount, 1);
    expect(lanes.linesOn('2026-08-22'), isEmpty);
    expect(lanes.linesOn('2026-08-23').single.pos, DayLinePos.start);
    expect(lanes.linesOn('2026-08-24').single.pos, DayLinePos.middle);
    expect(lanes.linesOn('2026-08-25').single.pos, DayLinePos.end);
    expect(lanes.linesOn('2026-08-26'), isEmpty);
  });

  /// **同じ期間の予定は 1 本を共有する。** 同じ期間に何品も出ると、
  /// 予定ごとに引くと同じ期間の線が並んで潰れる。
  test('同じ期間の予定は線を 1 本にまとめる', () {
    final lanes = buildDayLanes(
      [
        event(id: 'a', start: '2026-08-23', end: '2026-08-25'),
        event(id: 'b', start: '2026-08-23', end: '2026-08-25'),
        event(id: 'c', start: '2026-08-23', end: '2026-08-25'),
      ],
      dates,
      today,
      category: 'menu',
    );

    expect(lanes.laneCount, 1);
    final line = lanes.linesOn('2026-08-24').single;
    expect(line.eventIds, hasLength(3));
  });

  test('重なる期間は別のレーンに載る', () {
    final lanes = buildDayLanes(
      [
        event(id: 'a', start: '2026-08-22', end: '2026-08-25'),
        event(id: 'b', start: '2026-08-23', end: '2026-08-26'),
      ],
      dates,
      today,
      category: 'menu',
    );

    expect(lanes.laneCount, 2);
    expect(lanes.linesOn('2026-08-24').map((l) => l.lane).toSet(), {0, 1});
  });

  /// **継続中は今日で切れるだけで終わっていない。** 終端の丸ポチを打たない。
  test('継続中の予定は今日まで伸びて、終端の丸を打たない', () {
    final lanes = buildDayLanes(
      [event(id: 'a', start: '2026-08-22', ongoing: true)],
      dates,
      today,
      category: 'menu',
    );

    expect(lanes.linesOn('2026-08-24').single.pos, DayLinePos.end);
    expect(lanes.linesOn('2026-08-24').single.ongoing, isTrue);
    expect(lanes.linesOn('2026-08-25'), isEmpty);
  });

  test('別のカテゴリは対象にならない', () {
    final lanes = buildDayLanes(
      [
        event(
          id: 'a',
          start: '2026-08-23',
          end: '2026-08-25',
          category: 'menu',
        ),
        event(
          id: 'b',
          start: '2026-08-23',
          end: '2026-08-25',
          category: 'campaign',
        ),
      ],
      dates,
      today,
      category: 'campaign',
    );

    expect(lanes.laneCount, 1);
    expect(lanes.linesOn('2026-08-24').single.eventIds, ['b']);
  });

  /// **線は一番上の丸ポチから降ろす。** 最小に取らないと、上の丸ポチに繋がらず
  /// 「丸ポチだけ浮いて線が一段下から始まる」＝点と線で途切れて見える。
  test('始まる日は、その日の一番上の行から線を降ろす', () {
    final lanes = buildDayLanes(
      [
        // 並びは優先度 → タイトル。同カテゴリなのでタイトル順になる
        event(id: 'b', start: '2026-08-23', end: '2026-08-25', title: 'B'),
        event(id: 'a', start: '2026-08-23', end: '2026-08-25', title: 'A'),
      ],
      dates,
      today,
      category: 'menu',
    );

    final line = lanes.linesOn('2026-08-23').single;
    expect(line.pos, DayLinePos.start);
    expect(line.entryIndex, 0);
    // 0 行目は丸ポチの下から、それ以降は行の高さいっぱい
    expect(line.spanInRow(0), LineSpan.below);
    expect(line.spanInRow(1), LineSpan.full);
  });

  /// **`entryIndex` は描画側と同じ並びで取る。** 並びが食い違うと、`below`
  /// （線の始まり）が**線を持たない行**に付く ——「丸ポチだけ浮いて線が一段下から
  /// 始まる」形になる（gyumesy の注記）。
  ///
  /// **gyumesy との違い:** あちらは両方とも配信の順のまま数えていたが、とん速の
  /// web は優先度 → 題で並べ直すので、両方とも `dayEntries` を通す。
  test('entryIndex は描画側と同じ並び（優先度 → 題）で数える', () {
    // 配信の順は「期間持ち → 単日」。題の順では単日（A）が先に来る
    final events = [
      event(id: 'span', start: '2026-08-23', end: '2026-08-25', title: 'B'),
      event(id: 'single', start: '2026-08-23', title: 'A'),
    ];
    final lanes = buildDayLanes(events, dates, today, category: 'menu');

    // 描画側の並び
    final rows = buildMonthDays(
      events,
      '2026-08',
      today,
    ).firstWhere((d) => d.date == '2026-08-23').events;
    expect([for (final e in rows) e.id], ['single', 'span']);

    final line = lanes.linesOn('2026-08-23').single;
    // **線を持つのは 2 行目**（添字 1）。0 にすると単日の行に線が付く
    expect(line.entryIndex, 1);
    expect(line.spanInRow(0), LineSpan.none);
    expect(line.spanInRow(1), LineSpan.below);
  });

  /// **終わる線はその日の先頭行にだけ引く。** 全行に引くと、同じ日に予定が
  /// 複数ある時に**行ごとに 12px の切れ端が並ぶ**（実機で出た）。
  /// web は `applyListLineMode` が表示中の先頭行以外を消している。
  test('終わる線は先頭行にだけ引く', () {
    final lanes = buildDayLanes(
      [event(id: 'a', start: '2026-08-22', end: '2026-08-24')],
      dates,
      today,
      category: 'menu',
    );

    final line = lanes.linesOn('2026-08-24').single;
    expect(line.pos, DayLinePos.end);
    expect(line.spanInRow(0), LineSpan.above);
    // **2 行目以降には引かない**
    expect(line.spanInRow(1), LineSpan.none);
    expect(line.spanInRow(2), LineSpan.none);
  });

  test('単日の予定には線を引かない', () {
    final lanes = buildDayLanes(
      [event(id: 'a', start: '2026-08-23')],
      dates,
      today,
      category: 'menu',
    );
    expect(lanes.laneCount, 0);
    expect(lanes.linesOn('2026-08-23'), isEmpty);
  });
}
