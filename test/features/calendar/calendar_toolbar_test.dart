import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/calendar/presentation/calendar_page.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 貼り付く帯の積み上がり。
void main() {
  Future<double> pumpToolbar(
    WidgetTester tester, {
    String? lineMode,
    List<Tag> childTags = const [],
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: CalendarToolbar(
                month: '2026-08',
                range: (min: '2026-01', max: '2026-12'),
                onShift: (_) {},
                onToday: () {},
                categories: const [
                  Category(slug: 'menu', label: 'メニュー'),
                  Category(slug: 'official', label: '公式'),
                ],
                lineMode: lineMode,
                onSelectLineMode: (_) {},
                childTags: childTags,
                selectedChildTags: const {},
                onToggleChildTag: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.getSize(find.byType(CalendarToolbar)).height;
  }

  /// **子フィルタが 0 件のカテゴリを選んでも高さを変えない。**
  ///
  /// 間隔（`gap`）だけ残すと、そのカテゴリを選んだ瞬間に 8pt の空白が黙って
  /// 開く。`tags.json` にラベルのあるタグを 1 つも持たないカテゴリ（とん速の
  /// 本番のキャンペーンの一部）で普通に踏む（web は器の `gap-2` なので、子が
  /// `hidden` になれば一緒に消える）。
  testWidgets('子フィルタが 0 件なら間隔ごと出さない', (tester) async {
    final all = await pumpToolbar(tester);
    final emptyChild = await pumpToolbar(tester, lineMode: 'official');

    expect(emptyChild, all, reason: '子フィルタが無いのに間隔だけ増えている');
  });

  testWidgets('子フィルタがあれば間隔ごと出す', (tester) async {
    final all = await pumpToolbar(tester);
    final withChild = await pumpToolbar(
      tester,
      lineMode: 'menu',
      childTags: const [Tag(slug: 'limited', label: '期間限定')],
    );

    expect(
      withChild,
      greaterThan(all + CalendarToolbar.gap),
      reason: '子フィルタの行が積まれていない',
    );
  });
}
