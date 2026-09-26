import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/notifications/presentation/widgets/notification_sample.dart';

/// 仮名（平仮名・片仮名。全角の中黒 `・` と長音 `ー` もこの範囲）。
final _kana = RegExp('[぀-ヿ]');

/// 通知の見本。**画像だった時は英語・中国語の画面にも日本語が出ていた**
/// （ユーザーの決定「英語・中国語の画面に日本語を 1 文字も残さない」）。
void main() {
  Future<void> pumpSamples(
    WidgetTester tester,
    AppLocale locale,
    Brightness brightness,
  ) async {
    final samples = NotificationSample.all(
      AppMessages.of(locale),
      locale,
      brightness,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // **全部を組む**（`ListView` は画面外を組まない）。幅は SP の
          // 1 枚ぶん（375 - 左右 16）
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (final s in samples) SizedBox(width: 343, child: s),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 見本の中に描かれた字を全部つなぐ。
  String drawnText(WidgetTester tester) => tester
      .widgetList<RichText>(
        find.descendant(
          of: find.byType(NotificationSample),
          matching: find.byType(RichText),
        ),
      )
      .map((w) => w.text.toPlainText())
      .join('\n');

  for (final locale in [AppLocale.en, AppLocale.zh]) {
    for (final brightness in Brightness.values) {
      testWidgets('${locale.code} / ${brightness.name}: 見本に仮名を出さない', (
        tester,
      ) async {
        await pumpSamples(tester, locale, brightness);

        final text = drawnText(tester);
        expect(find.byType(NotificationSample), findsNWidgets(5));
        // 名乗り・時刻・題・本文の全部が描かれている（空で素通りしない）
        expect(text, contains(AppMessages.of(locale).appName));
        expect(
          text,
          contains(AppMessages.of(locale).notificationsSamples.first.body),
        );
        expect(_kana.allMatches(text).map((m) => m[0]), isEmpty);
      });
    }
  }

  testWidgets('日本語は web の見本と同じ文言で描く', (tester) async {
    await pumpSamples(tester, AppLocale.ja, Brightness.light);

    final text = drawnText(tester);
    expect(text, contains('とん速 ・たった今'));
    expect(text, contains('メニュー'));
    expect(text, contains('松のや、合い盛りタレかつ丼を掲載'));
    expect(text, contains('とん速 ・1時間前'));
  });

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name}: そのテーマの地で描く', (tester) async {
      await pumpSamples(tester, AppLocale.ja, brightness);

      expect(tester.takeException(), isNull);
      final card = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(NotificationSample).first,
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (card.decoration as BoxDecoration).color,
        NotificationSamplePalette.of(brightness).card,
      );
    });
  }

  test('時刻の数と見本の数が 3 言語とも揃っている', () {
    for (final locale in AppLocale.values) {
      expect(
        AppMessages.of(locale).notificationsSamples,
        hasLength(NotificationSample.ages.length),
        reason: locale.code,
      );
    }
  });

  group('本文が 1 行に収まる', () {
    // web の `.txt` の幅（`width:360px` / `font-size:17px`）
    const width = 360.0;
    const fontSize = 17.0;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // **同梱の書体で測る。** テストの既定の書体（Ahem）は字幅が実物と違う
      final loader = FontLoader(AppTheme.defaultFontFamily)
        ..addFont(rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf'));
      await loader.load();
    });

    for (final locale in [AppLocale.ja, AppLocale.en]) {
      test(locale.code, () {
        for (final s in AppMessages.of(locale).notificationsSamples) {
          final painter = TextPainter(
            text: TextSpan(
              text: s.body,
              style: const TextStyle(
                fontFamily: AppTheme.defaultFontFamily,
                fontSize: fontSize,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout(maxWidth: width);
          expect(painter.didExceedMaxLines, isFalse, reason: s.body);
          painter.dispose();
        }
      });
    }

    // **中国語は同梱の書体に無い字が多く**（簡体字は OS の書体へ落ちる）、
    // テストでは実物の幅を測れない。CJK の字は 1 字 1em を超えないので、
    // 字数 x 字の大きさで上から抑える
    test('zh', () {
      for (final s in AppMessages.of(AppLocale.zh).notificationsSamples) {
        expect(
          s.body.length * fontSize,
          lessThanOrEqualTo(width),
          reason: s.body,
        );
      }
    });
  });
}
