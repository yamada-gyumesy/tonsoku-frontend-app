import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/features/home/presentation/widgets/limited_weeks_section.dart';
import 'package:tonsoku/shared/models/limited_week.dart';

void main() {
  final t = AppMessages.ja;
  const item = LimitedWeekItem(
    cmsId: '1',
    name: '極厚肩ロース定食',
    articleSlug: 'abc',
    shopCount: 15,
    shopsLive: 9,
    shopsEnded: 6,
  );

  test('pending と知らない状態は出さず、新しい順に 4 週まで', () {
    final weeks = [
      const LimitedWeek(
        weekStart: '2026-09-30',
        weekEnd: '2026-10-06',
        status: 'pending',
      ),
      const LimitedWeek(
        weekStart: '2026-09-23',
        weekEnd: '2026-09-29',
        status: 'items',
        items: [item],
      ),
      const LimitedWeek(
        weekStart: '2026-09-16',
        weekEnd: '2026-09-22',
        status: 'none',
      ),
      const LimitedWeek(
        weekStart: '2026-09-09',
        weekEnd: '2026-09-15',
        status: 'unknown',
      ),
      const LimitedWeek(
        weekStart: '2026-09-02',
        weekEnd: '2026-09-08',
        status: 'none',
      ),
      const LimitedWeek(
        weekStart: '2026-08-26',
        weekEnd: '2026-09-01',
        status: 'none',
      ),
      const LimitedWeek(
        weekStart: '2026-08-19',
        weekEnd: '2026-08-25',
        status: 'none',
      ),
    ];
    final cards = limitedCards(weeks, t, today: '2026-09-25');
    expect(cards.map((c) => c.week), ['9/23週', '9/16週', '9/2週', '8/26週']);
  });

  test('「なし」は今週かどうかで言い分ける', () {
    const week = LimitedWeek(
      weekStart: '2026-09-23',
      weekEnd: '2026-09-29',
      status: 'none',
    );
    expect(
      (limitedCards([week], t, today: '2026-09-23').single as LimitedNoneCard)
          .label,
      '今週はなし',
    );
    expect(
      (limitedCards([week], t, today: '2026-09-30').single as LimitedNoneCard)
          .label,
      'この週はなし',
    );
  });

  test('店の数は 3 通りに出し分ける', () {
    LimitedItemCard card(LimitedWeekItem i) =>
        limitedCards(
              [
                LimitedWeek(
                  weekStart: '2026-09-23',
                  weekEnd: '2026-09-29',
                  status: 'items',
                  items: [i],
                ),
              ],
              t,
              today: '2026-09-25',
            ).single
            as LimitedItemCard;

    // 一部の店で売り終わった
    expect(card(item).shops, '9店舗（終売: 6店舗）');
    // 終売した（確定時点の数のまま）
    final ended = card(
      item.copyWith(shopsLive: 0, shopsEnded: 15, endedAt: '2026-09-20'),
    );
    expect(ended.shops, '15店舗');
    expect(ended.ended, isTrue);
    // 全店で売っている
    expect(card(item.copyWith(shopsLive: 15, shopsEnded: 0)).shops, '15店舗');
  });
}
