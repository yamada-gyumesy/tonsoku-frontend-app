import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
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

  /// 英語・中国語で訳の無い品は `name` が null（tonsoku-backend-batch#286）。
  /// **品名の行は空のまま高さを取り、カードは記事へ開ける**（web の
  /// `CoLimitedWeeks` と同じ）。
  group('品名が null（英語・中国語で訳が無い）', () {
    final week = LimitedWeek(
      weekStart: '2026-09-23',
      weekEnd: '2026-09-29',
      status: 'items',
      items: [
        item.copyWith(cmsId: '1', name: 'Thick-Cut Pork Loin Set Meal'),
        item.copyWith(cmsId: '2', name: null, articleSlug: 'untranslated'),
      ],
    );

    test('カードの品名は null のまま', () {
      final cards = limitedCards([week], AppMessages.en, today: '2026-09-25');
      expect((cards.last as LimitedItemCard).name, isNull);
    });

    testWidgets('行は空のまま同じ高さを取り、記事へ開ける', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'en'});
      final store = await SharedPreferences.getInstance();
      String? opened;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(store)],
          child: MaterialApp(
            theme: AppTheme.light(AppLocale.en),
            home: Scaffold(
              body: LimitedWeeksSection(
                weeks: [week],
                onOpenArticle: (slug) => opened = slug,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final named = find.text('Thick-Cut Pork Loin Set Meal');
      expect(named, findsOneWidget);
      // 品名の欄（2 行ぶんの高さの箱）は 2 枚とも同じ高さ
      final boxes = find.ancestor(
        of: find.byType(Text),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 13 * 1.375 * 2,
        ),
      );
      expect(boxes, findsNWidgets(2));
      // 日本語の品名に落とさない
      expect(find.textContaining('極厚'), findsNothing);

      await tester.tap(find.byType(InkWell).last);
      expect(opened, 'untranslated');
    });
  });
}
