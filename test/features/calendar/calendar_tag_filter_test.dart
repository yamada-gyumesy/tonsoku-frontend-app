import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/calendar/presentation/calendar_page.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';

/// タグの絞り込みが**月グリッドにも効く**こと。
///
/// **実機で見つかった。** グリッドだけ絞り込み前の全予定を渡していたので、
/// タグを押しても線と丸ポチが 1 つも減らず、日リストだけが変わっていた。
void main() {
  // グリッドの当月が固定になるよう、今日を含む月の予定にする
  final today = DateTime.now();
  String iso(int day) =>
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  final tagged = CalendarEvent(
    id: 'tagged',
    title: '期間限定のほう',
    category: 'menu',
    startDate: iso(10),
    tags: const ['term-limited'],
  );
  final untagged = CalendarEvent(
    id: 'untagged',
    title: 'タグなしのほう',
    category: 'menu',
    startDate: iso(11),
  );

  Finder segmentOf(String id) =>
      find.byKey(ValueKey('calendar-segment-$id'), skipOffstage: false);

  Future<void> pump(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          calendarProvider.overrideWith(
            (ref) => Stream.value(CalendarPayload(events: [tagged, untagged])),
          ),
          categoriesProvider.overrideWith(
            (ref) =>
                Stream.value(const [Category(slug: 'menu', label: 'メニュー')]),
          ),
          tagsProvider.overrideWith(
            (ref) =>
                Stream.value(const [Tag(slug: 'term-limited', label: '期間限定')]),
          ),
          // 記事の一覧は届いていない扱い（リンクを外さない。取得を組まない）
          articleIndexProvider.overrideWith(
            (ref) => const Stream<List<ArticleMeta>>.empty(),
          ),
          feedProvider.overrideWith(
            (ref) => const Stream<List<ArticleMeta>>.empty(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: CalendarPage(onOpenArticle: (_) {}),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('タグを押すと月グリッドからも落ちる', (tester) async {
    await pump(tester);

    // 絞り込み前はどちらもグリッドに居る
    expect(segmentOf('tagged'), findsOneWidget);
    expect(segmentOf('untagged'), findsOneWidget);

    // カテゴリ → タグ の順に押す（タグのチップはカテゴリを選ぶまで出ない）。
    //
    // **日リストの行も同じ文字を出す**ので、帯の中に絞ってから探す。
    //
    // gyumesy は帯が `NestedScrollView` のヘッダーの中にあり、テスト環境で
    // 描画位置とヒットテストの位置がずれるのでコールバックを直に呼んでいた。
    // とん速の帯は一覧の中の普通の行なので、そのまま押せる
    Future<void> pressChip(String label) async {
      final target = find.descendant(
        of: find.byType(CalendarToolbar),
        matching: find.text(label),
      );
      expect(target, findsOneWidget, reason: 'チップ「$label」が出ていない');
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 300));
    }

    await pressChip('メニュー');
    await pressChip('期間限定');

    // **押したタグを持たない予定はグリッドからも消える**
    expect(segmentOf('tagged'), findsOneWidget);
    expect(segmentOf('untagged'), findsNothing);

    // **もう一度押すと戻る。** 同じ `Set` を書き換えて渡していると、
    // `didUpdateWidget` が変化を検知できず強調も絞り込みも取り残される
    await pressChip('期間限定');
    expect(segmentOf('untagged'), findsOneWidget);
  });
}
