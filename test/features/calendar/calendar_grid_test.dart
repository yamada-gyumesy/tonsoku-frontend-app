import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/calendar/domain/calendar_grid.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

/// 月グリッドの幾何計算。**ここが崩れると月表示が黙って壊れる**
/// （線が消える・別のレーンに飛ぶ・`+N` の数が合わない）ので、
/// 判定の境目を実際の値で固定する。
void main() {
  CalendarEvent event({
    required String id,
    required String start,
    String? end,
    bool ongoing = false,
    String category = 'menu',
  }) => CalendarEvent(
    id: id,
    title: id,
    category: category,
    startDate: start,
    endDate: end,
    ongoing: ongoing,
  );

  group('週の並び', () {
    test('その月を含む週を日曜始まりで返す', () {
      final weeks = monthWeeks('2026-08');

      // 2026-08-01 は土曜。最初の週は 7/26（日）から
      expect(weeks.first.first, '2026-07-26');
      expect(weeks.first.last, '2026-08-01');
      // 2026-08-31 は月曜。最後の週は 8/30（日）から
      expect(weeks.last.first, '2026-08-30');
      expect(weeks.last.last, '2026-09-05');
      expect(weeks.every((w) => w.length == 7), isTrue);
    });

    test('1日が日曜の月でも週を余分に作らない', () {
      // 2026-11-01 は日曜
      final weeks = monthWeeks('2026-11');
      expect(weeks.first.first, '2026-11-01');
    });
  });

  group('線を引くか', () {
    const today = '2026-08-24';

    test('終了日があれば線', () {
      final e = event(id: 'a', start: '2026-08-20', end: '2026-08-27');
      expect(hasSpan(e, today), isTrue);
      expect(spanEnd(e, today), '2026-08-27');
    });

    test('継続中は今日まで伸ばす', () {
      final e = event(id: 'a', start: '2026-08-20', ongoing: true);
      expect(hasSpan(e, today), isTrue);
      expect(spanEnd(e, today), today);
    });

    test('まだ始まっていない継続中は丸ポチだけ', () {
      // 伸ばす先が無いので、開始日＝終端の 1 日の線になり途切れて見える
      final e = event(id: 'a', start: '2026-08-30', ongoing: true);
      expect(hasSpan(e, today), isFalse);
      expect(spanEnd(e, today), '2026-08-30');
    });

    test('終了日が開始日と同じなら単日', () {
      final e = event(id: 'a', start: '2026-08-20', end: '2026-08-20');
      expect(hasSpan(e, today), isFalse);
    });

    test('線は選んだカテゴリだけ', () {
      final e = event(id: 'a', start: '2026-08-20', end: '2026-08-27');
      expect(drawsLine(e, null, today), isFalse, reason: 'すべて では線を出さない');
      expect(drawsLine(e, 'menu', today), isTrue);
      expect(drawsLine(e, 'store', today), isFalse);
    });
  });

  group('レーンの割り当て', () {
    const today = '2026-08-24';
    // 2026-08-23（日）〜 08-29（土）
    final week = monthWeeks('2026-08')[4];

    test('すべて では線を引かず、開始日に丸ポチだけ', () {
      final layout = layoutWeek(
        week,
        [event(id: 'a', start: '2026-08-24', end: '2026-08-28')],
        null,
        today,
      );

      expect(layout.segments, hasLength(1));
      final segment = layout.segments.single;
      expect(segment.hasPeriod, isFalse);
      expect(segment.colStart, 1, reason: '月曜');
      expect(segment.colEnd, 1, reason: '丸ポチは 1 列だけ占有する');
    });

    test('カテゴリを選ぶと、その予定だけ線になる', () {
      final layout = layoutWeek(
        week,
        [
          event(id: 'a', start: '2026-08-24', end: '2026-08-28'),
          event(id: 'b', start: '2026-08-25', category: 'store'),
        ],
        'menu',
        today,
      );

      expect(layout.segments.map((s) => s.events.single.id), ['a']);
      expect(layout.segments.single.hasPeriod, isTrue);
      expect(layout.segments.single.colEnd, 5, reason: '金曜まで');
    });

    test('同じ期間の予定は 1 本の線を共有する', () {
      // 同日同カテゴリが並ぶと線が何本も重なって読めなくなる
      final layout = layoutWeek(
        week,
        [
          event(id: 'a', start: '2026-08-24', end: '2026-08-28'),
          event(id: 'b', start: '2026-08-24', end: '2026-08-28'),
          event(id: 'c', start: '2026-08-24', end: '2026-08-28'),
        ],
        'menu',
        today,
      );

      expect(layout.segments, hasLength(1));
      expect(layout.segments.single.events.map((e) => e.id), ['a', 'b', 'c']);
    });

    test('週をまたぐ線は端まで伸ばす', () {
      final layout = layoutWeek(
        week,
        [event(id: 'a', start: '2026-08-20', end: '2026-09-03')],
        'menu',
        today,
      );

      final segment = layout.segments.single;
      expect(segment.startsHere, isFalse);
      expect(segment.endsHere, isFalse);
      expect(segment.colStart, 0);
      expect(segment.colEnd, 6);
    });

    test('継続中は終端の形が変わる', () {
      final layout = layoutWeek(
        week,
        [event(id: 'a', start: '2026-08-20', ongoing: true)],
        'menu',
        today,
      );

      final segment = layout.segments.single;
      // 今日（月曜の翌日）で切れる
      expect(segment.endsHere, isTrue);
      expect(segment.ended, isFalse, reason: '終了日が決まっていない');
      expect(segment.ongoing, isTrue);
    });

    test('$maxLanes 本を超えたぶんは +N に回す', () {
      final layout = layoutWeek(
        week,
        [
          for (var i = 0; i < maxLanes + 2; i++)
            event(
              id: 'e$i',
              // 期間をずらして同じ列を取り合わせる
              start: '2026-08-24',
              end: '2026-08-28',
              category: 'menu',
            ),
        ],
        null,
        today,
      );

      expect(layout.segments, hasLength(maxLanes));
      expect(
        layout.segments.map((s) => s.lane),
        List.generate(maxLanes, (i) => i),
      );
      // 月曜に 2 件あふれる
      expect(layout.overflow[1], hasLength(2));
      expect(layout.overflow[0], isEmpty);
    });

    test('+N は動きのある日だけ数える（通過中の線は数えない）', () {
      // その日に何か起きたわけではないので
      final events = [
        // 期間をずらす（同じ期間だと 1 本の線を共有してしまう）
        for (var i = 0; i < maxLanes; i++)
          event(id: 'fill$i', start: '2026-08-23', end: '2026-08-2${4 + i}'),
        // 載らない。始まりは前の週、終わりは次の週
        event(id: 'through', start: '2026-08-20', end: '2026-09-03'),
      ];
      final layout = layoutWeek(week, events, 'menu', today);

      expect(layout.segments, hasLength(maxLanes));
      expect(
        layout.overflow.every((day) => day.isEmpty),
        isTrue,
        reason: '通過中の線は +N に数えない',
      );
    });
  });

  group('同点の並び', () {
    const today = '2026-08-24';
    final week = monthWeeks('2026-08')[4];

    test('同点は元の並び順を保つ（レーンが入力順で動かない）', () {
      // **`List.sort` は安定ではない**（同点だけの配列でも 10 件から崩れる）。
      // 崩れると、同じ日の丸ポチの上下が入れ替わるだけでなく **`+N` に落ちる
      // 予定が変わって「見えていたものが隠れる」**
      final events = [
        for (var i = 0; i < 40; i++)
          event(id: 'e${i.toString().padLeft(2, '0')}', start: '2026-08-24'),
      ];
      final layout = layoutWeek(week, events, null, today);

      // 先頭から順に載る
      expect(layout.segments.map((s) => s.events.single.id), [
        for (var i = 0; i < maxLanes; i++) 'e${i.toString().padLeft(2, '0')}',
      ]);
      // あふれるのは残り全部
      expect(layout.overflow[1], hasLength(40 - maxLanes));
    });

    test('無関係な予定を足しても、ほかの予定のレーンが動かない', () {
      Map<String, int> lanesOf(List<CalendarEvent> events) => {
        for (final s in layoutWeek(week, events, null, today).segments)
          s.events.single.id: s.lane,
      };

      final base = [
        for (var i = 0; i < 30; i++)
          event(id: 'e${i.toString().padLeft(2, '0')}', start: '2026-08-24'),
      ];
      final before = lanesOf(base);

      // 別の日の予定を足す（同じ列を取り合わない）
      final after = lanesOf([...base, event(id: 'other', start: '2026-08-27')]);

      // 足したぶん以外は 1 件もレーンが動かない
      expect(after..remove('other'), before);
    });
  });
}
