import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/article/presentation/widgets/article_markdown.dart';

/// 箇条書きの記号。**「・」（片仮名の中点）は日本語の画面だけ**
/// （英語・中国語の画面に日本語を出さない。Issue #35）。
void main() {
  for (final (locale, bullet, other) in const [
    (AppLocale.ja, '・', '•'),
    (AppLocale.en, '•', '・'),
    (AppLocale.zh, '•', '・'),
  ]) {
    testWidgets('${locale.code}: 箇条書きは「$bullet」', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(locale),
          locale: locale.flutterLocale,
          supportedLocales: AppLocale.values.map((l) => l.flutterLocale),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const Scaffold(body: ArticleMarkdown(markdown: '- a\n- b')),
        ),
      );
      expect(find.text(bullet), findsNWidgets(2));
      expect(find.text(other), findsNothing);
    });
  }
}
