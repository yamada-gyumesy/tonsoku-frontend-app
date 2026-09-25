import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/core/theme/theme_mode_controller.dart';
import 'package:tonsoku/features/menu/presentation/menu_sheet.dart';
import 'package:tonsoku/features/ranking/data/ranking_repository.dart';
import 'package:tonsoku/features/menu/presentation/widgets/menu_list_row.dart';
import 'package:tonsoku/features/menu/presentation/widgets/theme_switch.dart';

/// メニューのボトムシート。web の `CoMenuSheet` に合わせている。
void main() {
  Future<GlobalKey<MenuSheetState>> pumpSheet(
    WidgetTester tester, {
    Brightness platform = Brightness.light,
    Map<String, Object> prefs = const {},
  }) async {
    // **表示言語を固定する。** 既定は端末の言語設定から推定するので、
    // 指定しないと実行環境（テストは en）で文言が変わる
    SharedPreferences.setMockInitialValues({'app_locale': 'ja', ...prefs});
    final store = await SharedPreferences.getInstance();
    final key = GlobalKey<MenuSheetState>();
    var open = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          // ランキングの行は配信を見て出し分ける。テストでは取得中として置く
          // （配信の取得を組まない）
          rankingWindowsProvider.overrideWithValue(const AsyncValue.loading()),
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
                      onOpenRanking: () {},
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
    // **特商法は置かない。** アプリ内に有償の取引が無いので対象にならない
    expect(find.text('特定商取引法に基づく表記'), findsNothing);

    // **通知設定の行はまだ無い**（通知の Issue #6 で足す。受け口の無い行を置かない）
    expect(find.widgetWithText(MenuListRow, '通知設定'), findsNothing);
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
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          // `AppShell` と同じ置き方（本文の中に重ね、ナビは器の外）
          home: Scaffold(
            body: Stack(
              children: [
                const SizedBox.expand(child: Text('本文')),
                MenuSheet(onClose: () {}, onOpenRanking: () {}),
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
      // 有償の取引が無いので対象にならない
      expect(find.text('特定商取引法に基づく表記'), findsNothing);
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
                  if (open) MenuSheet(onClose: () {}, onOpenRanking: () {}),
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
}
