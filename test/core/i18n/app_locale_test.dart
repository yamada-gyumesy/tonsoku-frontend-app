import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';

void main() {
  group('fromSystem', () {
    test('先頭が対応言語ならそれを採る', () {
      expect(
        AppLocale.fromSystem([const Locale('en'), const Locale('ja')]),
        AppLocale.en,
      );
    });

    test('先頭が非対応でも、後続に対応言語があればそれを採る', () {
      // 韓国語が第1希望・英語が第2希望の端末。先頭だけを見ると日本語に落ちる
      expect(
        AppLocale.fromSystem([const Locale('ko'), const Locale('en')]),
        AppLocale.en,
      );
    });

    test('対応言語が1つも無ければ日本語', () {
      expect(
        AppLocale.fromSystem([const Locale('ko'), const Locale('fr')]),
        AppLocale.ja,
      );
    });

    test('空リストでも日本語に落ちる', () {
      expect(AppLocale.fromSystem(const []), AppLocale.ja);
    });

    test('繁体字も簡体字に寄せる', () {
      expect(
        AppLocale.fromSystem([
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ]),
        AppLocale.zh,
      );
      expect(AppLocale.fromSystem([const Locale('zh', 'TW')]), AppLocale.zh);
    });
  });

  test('日本語だけが名前空間のルート扱い', () {
    expect(AppLocale.ja.isDefault, isTrue);
    expect(AppLocale.en.isDefault, isFalse);
    expect(AppLocale.zh.isDefault, isFalse);
  });

  test('fromCode は未知のコードで null', () {
    expect(AppLocale.fromCode('en'), AppLocale.en);
    expect(AppLocale.fromCode('ko'), isNull);
    expect(AppLocale.fromCode(null), isNull);
  });
}
