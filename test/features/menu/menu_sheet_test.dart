import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/purchase/purchase_gateway.dart';
import 'package:tonsoku/core/purchase/remove_ads_controller.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/core/theme/theme_mode_controller.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/menu/presentation/menu_sheet.dart';
import 'package:tonsoku/features/ranking/data/ranking_repository.dart';
import 'package:tonsoku/features/menu/presentation/widgets/menu_list_row.dart';
import 'package:tonsoku/features/menu/presentation/widgets/theme_switch.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

import '../../core/purchase/fake_purchase_gateway.dart';

/// メニューのボトムシート。web の `CoMenuSheet` に合わせている。
void main() {
  Future<GlobalKey<MenuSheetState>> pumpSheet(
    WidgetTester tester, {
    Brightness platform = Brightness.light,
    Map<String, Object> prefs = const {},
    AsyncValue<List<CalendarEvent>> calendar = const AsyncValue.loading(),
    FakePurchaseGateway? store,
    AppLocale locale = AppLocale.ja,
    bool started = false,
  }) async {
    // **電話の大きさで組む**（iPhone 17 Pro の論理 402×874）。既定の 800×600 は
    // 背が低く、シートの上限（画面の 7 割）を一覧が超えて中で送れるようになり、
    // 行の上から払っても一覧のスクロールが先に取る
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // **表示言語を固定する。** 既定は端末の言語設定から推定するので、
    // 指定しないと実行環境（テストは en）で文言が変わる
    SharedPreferences.setMockInitialValues({
      'app_locale': locale.name,
      ...prefs,
    });
    final prefsStore = await SharedPreferences.getInstance();
    final key = GlobalKey<MenuSheetState>();
    var open = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefsStore),
          // **本物のストアに触れない**（広告を外す課金の行）
          purchaseGatewayProvider.overrideWithValue(
            store ?? FakePurchaseGateway(),
          ),
          // ランキングの行は配信を見て出し分ける。テストでは取得中として置く
          // （配信の取得を組まない）
          rankingWindowsProvider.overrideWithValue(const AsyncValue.loading()),
          // カレンダーの行も同じ（既定は取得中）
          calendarEventsProvider.overrideWithValue(calendar),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          darkTheme: AppTheme.dark(AppLocale.ja),
          themeMode: platform == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Stack(
                children: [
                  const SizedBox.expand(child: Text('本文')),
                  if (open)
                    MenuSheet(
                      key: key,
                      onOpenCalendar: () {},
                      onOpenRanking: () {},
                      onOpenNotifications: () {},
                      onClose: () => setState(() => open = false),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (started) {
      // 起動時の突き合わせ（`main.dart`）。価格はこの後に取れる
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MenuSheet)),
      );
      await container.read(removeAdsProvider.notifier).start();
      await tester.pumpAndSettle();
    }
    return key;
  }

  testWidgets('とん速の項目が並ぶ', (tester) async {
    await pumpSheet(tester);

    expect(find.text('とん速とは'), findsOneWidget);
    expect(find.text('外観モード'), findsOneWidget);
    expect(find.widgetWithText(MenuListRow, '言語'), findsOneWidget);

    // **法務ページはアプリではここが唯一の入口**（web はフッターに常設して
    // いてメニューには置かない）。落とすとストア審査で止まる
    expect(find.text('利用規約'), findsOneWidget);
    expect(find.text('プライバシーポリシー'), findsOneWidget);
    // **特商法は「その他」に置く**（広告を外す課金で有償の取引ができた）
    expect(find.text('特定商取引法に基づく表記'), findsOneWidget);

    // **通知設定の行は常に出す**（web と同じ。配信の有無に依らない面）
    expect(find.widgetWithText(MenuListRow, '通知設定'), findsOneWidget);
  });

  /// **並びはユーザーの指定。** web とも gyumesy とも違うので、写し直した時に
  /// 黙って戻らないよう固定する。
  testWidgets('並びは とん速とは → カレンダー → ランキング → 通知設定 → 外観 → 言語', (tester) async {
    await pumpSheet(tester);

    final labels = ['とん速とは', 'カレンダー', 'ランキング', '通知設定', '外観モード', '言語'];
    final tops = [
      for (final label in labels)
        tester.getTopLeft(find.widgetWithText(MenuListRow, label)).dy,
    ];
    for (var i = 1; i < tops.length; i++) {
      expect(
        tops[i],
        greaterThan(tops[i - 1]),
        reason: '${labels[i - 1]} の下に ${labels[i]}',
      );
    }
  });

  group('カレンダーの行', () {
    // 行ける月（2026-09〜今月から 3 ヶ月先）の判定を固定するため、今日を決める
    final today = DateTime.utc(2026, 9, 25, 3);

    CalendarEvent event(String start) => CalendarEvent(
      id: start,
      title: 't',
      category: 'menu',
      startDate: start,
    );

    Finder row() => find.widgetWithText(MenuListRow, 'カレンダー');

    testWidgets('取得中は出しておく', (tester) async {
      await pumpSheet(tester);
      expect(row(), findsOneWidget);
    });

    testWidgets('取れなかった時も出しておく（開いた先で再試行できる）', (tester) async {
      await pumpSheet(
        tester,
        calendar: AsyncValue.error(Exception('x'), StackTrace.empty),
      );
      expect(row(), findsOneWidget);
    });

    testWidgets('行ける月に予定があれば出す', (tester) async {
      await withClock(Clock.fixed(today), () async {
        await pumpSheet(
          tester,
          calendar: AsyncValue.data([event('2026-10-15')]),
        );
      });
      expect(row(), findsOneWidget);
    });

    testWidgets('予定が 0 件なら出さない', (tester) async {
      await pumpSheet(tester, calendar: const AsyncValue.data([]));
      expect(row(), findsNothing);
      // 並びの残りは崩れない
      expect(find.widgetWithText(MenuListRow, 'ランキング'), findsOneWidget);
    });

    /// **件数ではなく、画面に出る範囲で数える**（web の `hasEvents`）。下限
    /// （2026-09）より前の予定しか無いと、行はあるのに開いたら空になる。
    testWidgets('行けない月の予定しか無ければ出さない', (tester) async {
      await withClock(Clock.fixed(today), () async {
        await pumpSheet(
          tester,
          calendar: AsyncValue.data([event('2026-08-20')]),
        );
      });
      expect(row(), findsNothing);
    });

    testWidgets('押すと開く', (tester) async {
      SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
      final store = await SharedPreferences.getInstance();
      var opened = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(store),
            rankingWindowsProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
            calendarEventsProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppLocale.ja),
            home: Scaffold(
              body: MenuSheet(
                onClose: () {},
                onOpenCalendar: () => opened++,
                onOpenRanking: () {},
                onOpenNotifications: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(row());
      expect(opened, 1);
    });
  });

  testWidgets('暗幕を押すと閉じる', (tester) async {
    await pumpSheet(tester);
    expect(find.byType(MenuSheet), findsOneWidget);

    // シートの外（画面上端寄り）を押す
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    expect(find.byType(MenuSheet), findsNothing);
  });

  group('言語', () {
    testWidgets('選ぶと表示言語が変わり、メニューへ戻る', (tester) async {
      final key = await pumpSheet(tester);
      final ref = ProviderScope.containerOf(
        tester.element(find.byType(MenuSheet)),
      );
      expect(ref.read(localeControllerProvider), AppLocale.ja);

      await tester.tap(find.widgetWithText(MenuListRow, '言語'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(MenuListRow, 'English'), findsOneWidget);

      await tester.tap(find.widgetWithText(MenuListRow, 'English'));
      await tester.pumpAndSettle();

      expect(ref.read(localeControllerProvider), AppLocale.en);
      // 選び終わったらメニューへ戻る
      expect(find.widgetWithText(MenuListRow, 'Language'), findsOneWidget);
      expect(key.currentState, isNotNull);
    });

    testWidgets('戻る操作は、まずメニューへ戻すだけ', (tester) async {
      final key = await pumpSheet(tester);

      await tester.tap(find.widgetWithText(MenuListRow, '言語'));
      await tester.pumpAndSettle();

      // 言語を開いている間の戻るは、シートを閉じない（web が履歴を 2 段
      // 積んでいるのと同じ）
      key.currentState!.handleBack();
      await tester.pumpAndSettle();

      expect(find.byType(MenuSheet), findsOneWidget);
      expect(find.text('とん速とは'), findsOneWidget);

      // メニューまで戻ってからの戻るで閉じる
      key.currentState!.handleBack();
      await tester.pumpAndSettle();
      expect(find.byType(MenuSheet), findsNothing);
    });
  });

  group('外観モード', () {
    /// つまみの中心。左（ライト）にあるか右（ダーク）にあるかを見る。
    double thumbCenterX(WidgetTester tester) {
      final thumb = find
          .descendant(
            of: find.byType(ThemeSwitch),
            matching: find.byType(AnimatedPositioned),
          )
          .first;
      return tester.getCenter(thumb).dx;
    }

    testWidgets('OS 追従でも、いま効いている側が選ばれている', (tester) async {
      // web は選ぶまでつまみを隠すが、それだと壊れた操作部に見える
      await pumpSheet(tester, platform: Brightness.dark);
      final dark = thumbCenterX(tester);

      await pumpSheet(tester);
      final light = thumbCenterX(tester);

      expect(light, lessThan(dark));
    });

    testWidgets('押すと逆側へ固定される', (tester) async {
      await pumpSheet(tester);
      final ref = ProviderScope.containerOf(
        tester.element(find.byType(MenuSheet)),
      );
      expect(ref.read(themeModeControllerProvider), ThemeMode.system);

      await tester.tap(find.byType(ThemeSwitch));
      await tester.pumpAndSettle();

      // ライトが効いていたので、押したらダークに固定される
      expect(ref.read(themeModeControllerProvider), ThemeMode.dark);
    });
  });

  testWidgets('ナビはシートに覆われず、開いている間も押せる', (tester) async {
    // web もナビをシートより上に置き、暗幕をナビに掛けない。押した本人の
    // タブが隠れず、他のタブへも直接移れる
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    var tapped = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          // ランキングの行は配信を見て出し分ける。テストでは取得中として置く
          // （配信の取得を組まない）
          rankingWindowsProvider.overrideWithValue(const AsyncValue.loading()),
          calendarEventsProvider.overrideWithValue(const AsyncValue.loading()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          // `AppShell` と同じ置き方（本文の中に重ね、ナビは器の外）
          home: Scaffold(
            body: Stack(
              children: [
                const SizedBox.expand(child: Text('本文')),
                MenuSheet(
                  onClose: () {},
                  onOpenCalendar: () {},
                  onOpenRanking: () {},
                  onOpenNotifications: () {},
                ),
              ],
            ),
            bottomNavigationBar: SizedBox(
              height: 56,
              child: GestureDetector(
                onTap: () => tapped++,
                behavior: HitTestBehavior.opaque,
                child: const Center(child: Text('ホーム')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ホーム'));
    await tester.pump();

    expect(tapped, 1);
  });

  group('その他', () {
    Future<void> openOther(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    testWidgets('法務とライセンスとバージョンを置く', (tester) async {
      await pumpSheet(tester);
      // **メニュー本体には出さない。** 読む頻度が最も低いので、本体の並びより
      // 目立たせない。3 枚とも常に組まれているので、見えているかは位置で見る
      // （画面の右外に控えている）
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(
        tester.getTopLeft(find.text('利用規約')).dx,
        greaterThanOrEqualTo(width),
      );

      await openOther(tester);

      expect(find.text('利用規約'), findsOneWidget);
      expect(find.text('プライバシーポリシー'), findsOneWidget);
      expect(find.text('ライセンス表記'), findsOneWidget);
      expect(find.text('バージョン'), findsOneWidget);
      // **広告を外す課金を入れたので置く**（web の `LEGAL_PAGES` の 3 つ目）
      expect(find.text('特定商取引法に基づく表記'), findsOneWidget);
    });

    testWidgets('web へ出る行だけ外部リンクの記号にする', (tester) async {
      // 同じ「>」だと、アプリ内で階層が深くなるのか web へ出るのかが
      // 区別できない
      await pumpSheet(tester);
      await openOther(tester);

      Finder rowIcon(String label, IconData icon) => find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(MenuListRow),
        ),
        matching: find.byIcon(icon),
      );

      // **「>」は置き換えない。** 押せることは「>」が示していて、外へ出るか
      // どうかはそれとは別の情報
      expect(rowIcon('利用規約', Icons.open_in_new), findsOneWidget);
      expect(rowIcon('利用規約', Icons.chevron_right), findsOneWidget);
      expect(rowIcon('プライバシーポリシー', Icons.open_in_new), findsOneWidget);
      expect(rowIcon('プライバシーポリシー', Icons.chevron_right), findsOneWidget);
      // ライセンス表記はアプリ内の画面
      expect(rowIcon('ライセンス表記', Icons.chevron_right), findsOneWidget);
      expect(rowIcon('ライセンス表記', Icons.open_in_new), findsNothing);
    });

    testWidgets('戻る操作でメニューへ戻る', (tester) async {
      final key = await pumpSheet(tester);
      await openOther(tester);

      key.currentState!.handleBack();
      await tester.pumpAndSettle();

      expect(find.byType(MenuSheet), findsOneWidget);
      expect(find.text('とん速とは'), findsOneWidget);
    });
  });

  group('下に払って閉じる', () {
    // 取っ手（縦 20px）だけだと、閉じるのに細い帯を狙わせることになる
    testWidgets('行の上から払える', (tester) async {
      await pumpSheet(tester);

      await tester.drag(find.text('とん速とは'), const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(find.byType(MenuSheet), findsNothing);
    });

    testWidgets('取っ手の余白からも払える', (tester) async {
      // **利用者は「掴め」と示している取っ手めがけて指を置く。** バーの周りに
      // 当たる子が居ないと、シート上端に触れて払っても何も起きない
      await pumpSheet(tester);

      // 取っ手のバー（36×4）を見つけて、その 5px 上（余白のまん中）から払う
      final bar = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.maxWidth == 36,
      );
      final barRect = tester.getRect(bar);
      await tester.dragFrom(
        Offset(barRect.center.dx, barRect.top - 5),
        const Offset(0, 200),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MenuSheet), findsNothing);
    });
  });

  testWidgets('暗幕の下は読み上げからも外れる', (tester) async {
    // 暗くしてタップを止めるだけだと、読み上げの activate は
    // `SemanticsAction.tap` を直に送るのでヒットテストを迂回して発火する
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    var open = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          // ランキングの行は配信を見て出し分ける。テストでは取得中として置く
          // （配信の取得を組まない）
          rankingWindowsProvider.overrideWithValue(const AsyncValue.loading()),
          calendarEventsProvider.overrideWithValue(const AsyncValue.loading()),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Stack(
                children: [
                  ExcludeSemantics(
                    excluding: open,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('下の記事'),
                    ),
                  ),
                  if (open)
                    MenuSheet(
                      onClose: () {},
                      onOpenCalendar: () {},
                      onOpenRanking: () {},
                      onOpenNotifications: () {},
                    ),
                ],
              ),
              bottomNavigationBar: TextButton(
                onPressed: () => setState(() => open = !open),
                child: const Text('メニュー'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final handle = tester.ensureSemantics();

    // **意味木そのものを見る。** `find.bySemanticsLabel` はウィジェット木を
    // 探すので、`ExcludeSemantics` で落ちても見つかってしまう
    List<String> labels() {
      final found = <String>[];
      void walk(SemanticsNode node) {
        if (node.label.isNotEmpty) found.add(node.label);
        node.visitChildren((child) {
          walk(child);
          return true;
        });
      }

      // 意味木は子の PipelineOwner が持つ
      SemanticsNode? root;
      tester.binding.rootPipelineOwner.visitChildren((owner) {
        root ??= owner.semanticsOwner?.rootSemanticsNode;
      });
      walk(root!);
      return found;
    }

    expect(labels(), contains('下の記事'));

    await tester.tap(find.text('メニュー'));
    await tester.pumpAndSettle();

    expect(labels(), isNot(contains('下の記事')));
    // シート側は読める
    expect(labels(), contains('とん速とは'));

    handle.dispose();
  });

  group('広告を外す課金（Issue #42）', () {
    Finder row(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(MenuListRow));

    /// 購入の画面のボタン（メニューの行の形にしていない）。
    Finder buyButton() => find.byType(FilledButton);
    Finder restoreButton() => find.byType(OutlinedButton);
    String buyLabel(WidgetTester tester) => tester
        .widget<Text>(
          find.descendant(of: buyButton(), matching: find.byType(Text)),
        )
        .data!;

    /// メニューの一番上の入口から、購入の画面へ送る。
    Future<void> openRemoveAds(
      WidgetTester tester, [
      String label = '広告を非表示にする',
    ]) async {
      await tester.tap(row(label).first);
      await tester.pumpAndSettle();
    }

    testWidgets('入口はメニューの一番上に置き、押すと購入の画面へ送る', (tester) async {
      await pumpSheet(tester, started: true);

      // 一番上（見出しのすぐ下）の行
      final rows = tester
          .widgetList<MenuListRow>(find.byType(MenuListRow))
          .toList();
      expect(rows.first.label, '広告を非表示にする');
      // 入口では買わせない（入口の行に価格を出さない）
      expect(
        find.descendant(of: row('広告を非表示にする'), matching: find.text('¥550')),
        findsNothing,
      );

      await openRemoveAds(tester);
      expect(find.textContaining('永続的に適用'), findsOneWidget);
      expect(buyLabel(tester), '購入する（¥550）');
      expect(
        find.textContaining('iPhone と Android の間では引き継げません'),
        findsOneWidget,
      );
      expect(
        find.descendant(of: restoreButton(), matching: find.text('購入を復元')),
        findsOneWidget,
      );
    });

    testWidgets('マップから購入の画面で直に開ける', (tester) async {
      tester.view.physicalSize = const Size(1206, 2622);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
      final prefsStore = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefsStore),
            purchaseGatewayProvider.overrideWithValue(FakePurchaseGateway()),
            rankingWindowsProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
            calendarEventsProvider.overrideWithValue(
              const AsyncValue.loading(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppLocale.ja),
            home: Scaffold(
              body: MenuSheet(
                initialView: MenuSheet.removeAdsView,
                onOpenCalendar: () {},
                onOpenRanking: () {},
                onOpenNotifications: () {},
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('永続的に適用'), findsOneWidget);
      expect(buyButton(), findsOneWidget);
    });

    testWidgets('買ったら知らせ、「購入済み」にして押せなくする', (tester) async {
      final store = FakePurchaseGateway();
      await pumpSheet(tester, store: store, started: true);
      await openRemoveAds(tester);

      await tester.tap(buyButton());
      await tester.pump();
      await tester.pump();
      expect(find.text('広告を非表示にしました'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(buyLabel(tester), '購入済み');
      expect(tester.widget<FilledButton>(buyButton()).onPressed, isNull);
      // 復元は買ってあっても置く
      expect(restoreButton(), findsOneWidget);
      expect(store.calls.where((c) => c == 'buy'), hasLength(1));
    });

    testWidgets('買ってある端末は、入口にも「購入済み」を出す', (tester) async {
      await pumpSheet(tester, prefs: {RemoveAdsController.prefsKey: true});
      expect(
        find.descendant(of: row('広告を非表示にする'), matching: find.text('購入済み')),
        findsOneWidget,
      );
    });

    testWidgets('シートを閉じた時は何も知らせない', (tester) async {
      await pumpSheet(
        tester,
        store: FakePurchaseGateway(buyResult: PurchaseUpdate.canceled),
        started: true,
      );
      await openRemoveAds(tester);
      await tester.tap(buyButton());
      await tester.pump();
      await tester.pump();
      expect(find.text('購入できませんでした'), findsNothing);
      expect(find.text('広告を非表示にしました'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('購入済み'), findsNothing);
    });

    testWidgets('買えなかった・ストアに繋がらない時は知らせる', (tester) async {
      final store = FakePurchaseGateway(buyResult: PurchaseUpdate.failed);
      await pumpSheet(tester, store: store, started: true);
      await openRemoveAds(tester);
      await tester.tap(buyButton());
      await tester.pump();
      await tester.pump();
      expect(find.text('購入できませんでした'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      store.buyStart = BuyStart.unavailable;
      await tester.tap(buyButton());
      await tester.pump();
      await tester.pump();
      expect(find.text('ストアに接続できませんでした'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 4));
    });

    testWidgets('保留: 知らせて「保留中」にし、二重に買わせない', (tester) async {
      await pumpSheet(
        tester,
        store: FakePurchaseGateway(buyResult: PurchaseUpdate.pending),
        started: true,
      );
      await openRemoveAds(tester);
      await tester.tap(buyButton());
      await tester.pump();
      await tester.pump();
      expect(find.text('支払いが済むと広告が非表示になります'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(buyLabel(tester), '保留中');
      expect(tester.widget<FilledButton>(buyButton()).onPressed, isNull);
    });

    testWidgets('復元: 見つかった・見つからない', (tester) async {
      final store = FakePurchaseGateway(ownership: Ownership.notOwned);
      await pumpSheet(tester, store: store, started: true);
      await openRemoveAds(tester);

      await tester.tap(restoreButton());
      await tester.pump();
      await tester.pump();
      expect(find.text('復元できる購入はありません'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      store.ownership = Ownership.owned;
      await tester.tap(restoreButton());
      await tester.pump();
      await tester.pump();
      expect(find.text('購入を復元しました'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(buyLabel(tester), '購入済み');
    });

    for (final locale in [AppLocale.en, AppLocale.zh]) {
      testWidgets('${locale.name}: 課金の行と説明に仮名が出ない', (tester) async {
        // **英語・中国語の画面に日本語を出さない**（ユーザーの決定）
        await pumpSheet(tester, locale: locale, started: true);
        final kana = RegExp('[\u3040-\u30ff]');
        final t = locale == AppLocale.en ? AppMessages.en : AppMessages.zh;
        for (final text in [
          t.removeAds,
          t.removeAdsLead,
          t.removeAdsBuy,
          t.removeAdsRestoreNote,
          t.restorePurchase,
          t.removeAdsPurchased,
          t.removeAdsPending,
          t.removeAdsDone,
          t.restoreDone,
          t.restoreNotFound,
          t.purchasePendingNotice,
          t.purchaseFailed,
          t.storeUnavailable,
          t.mapRemoveAds,
          t.navSct,
        ]) {
          expect(kana.hasMatch(text), isFalse, reason: text);
        }
        await openRemoveAds(tester, t.removeAds);
        expect(buyButton(), findsOneWidget);
        expect(restoreButton(), findsOneWidget);
        final shown = tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => w.data ?? '')
            .where(kana.hasMatch);
        expect(shown, isEmpty);
      });
    }
  });
}
