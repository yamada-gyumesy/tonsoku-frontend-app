import 'package:flutter_test/flutter_test.dart';

import 'package:tonsoku/core/analytics/screen_path.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';

/// GA4 へ送るパスとページ名。
///
/// **web の URL と `<title>` に 1 文字違わず同じであること**が要件（Issue #7）。
/// 末尾スラッシュ 1 つの差で、永久に突き合わせられないレポートができる。
///
/// 期待値は **web（tonsoku-frontend-web）の実物から写した**:
/// パスは `localePaths`（`src/utils/paths.ts`）、題は各ページの
/// `{ページ名} | {site.titleSuffix}`（ホームは `site.defaultTitle`）。
void main() {
  /// 画面ごとの [ScreenPath] を作る。**アプリの画面を全部並べる**（足したら
  /// ここにも足す）。
  Map<String, ScreenPath> all(AppLocale l) {
    final t = AppMessages.of(l);
    return {
      'home': ScreenPath.home(l, t),
      'articles': ScreenPath.articles(l, t),
      'article': ScreenPath.article(
        l,
        t,
        slug: 'abc123',
        articleTitle: 'ロースかつ定食',
      ),
      'calendar': ScreenPath.calendar(l, t),
      'coupon': ScreenPath.coupon(l, t),
      'ranking': ScreenPath.ranking(l, t),
      'notifications': ScreenPath.notifications(l, t),
      'map': ScreenPath.map(l, t),
      'licenses': ScreenPath.licenses(l, t),
    };
  }

  /// web のパスと題（`screenClass` / `screenName` として GA4 に届く値）。
  const expected = {
    AppLocale.ja: {
      'home': ('/', 'とん速 | 松のや速報'),
      'articles': ('/articles/', '記事一覧 | とん速'),
      'article': ('/articles/abc123/', 'ロースかつ定食 | とん速'),
      'calendar': ('/calendar/', '松のやカレンダー | とん速'),
      'coupon': ('/coupon/', '松のやのクーポン | とん速'),
      'ranking': ('/ranking/', 'ランキング | とん速'),
      'notifications': ('/notifications/', '通知設定 | とん速'),
      // web に無い面は、スラッシュの無い識別子（`ScreenPath.appOnly`）
      'map': ('map', 'map'),
      'licenses': ('licenses', 'licenses'),
    },
    AppLocale.en: {
      'home': ('/en/', 'Tonsoku | Matsunoya News'),
      'articles': ('/en/articles/', 'All articles | Tonsoku'),
      'article': ('/en/articles/abc123/', 'ロースかつ定食 | Tonsoku'),
      'calendar': ('/en/calendar/', 'Matsunoya Calendar | Tonsoku'),
      'coupon': ('/en/coupon/', 'Matsunoya coupons | Tonsoku'),
      'ranking': ('/en/ranking/', 'Ranking | Tonsoku'),
      'notifications': ('/en/notifications/', 'Notifications | Tonsoku'),
      'map': ('map', 'map'),
      'licenses': ('licenses', 'licenses'),
    },
    AppLocale.zh: {
      // **中国語の接尾辞は `豚速`**（web の `site.titleSuffix`）
      'home': ('/zh/', '豚速 | 松乃家新闻媒体'),
      'articles': ('/zh/articles/', '全部文章 | 豚速'),
      'article': ('/zh/articles/abc123/', 'ロースかつ定食 | 豚速'),
      'calendar': ('/zh/calendar/', '松乃家日历 | 豚速'),
      'coupon': ('/zh/coupon/', '松乃家的优惠券 | 豚速'),
      'ranking': ('/zh/ranking/', '排行榜 | 豚速'),
      'notifications': ('/zh/notifications/', '通知设置 | 豚速'),
      'map': ('map', 'map'),
      'licenses': ('licenses', 'licenses'),
    },
  };

  for (final locale in AppLocale.values) {
    group('${locale.code}: web と同じパスと題', () {
      final screens = all(locale);
      test('期待値が全画面ぶんある', () {
        expect(screens.keys.toSet(), expected[locale]!.keys.toSet());
      });
      for (final MapEntry(key: name, value: (path, title))
          in expected[locale]!.entries) {
        test(name, () {
          final s = screens[name]!;
          expect(s.screenClass, path, reason: 'GA4 のパスの列（スクリーン クラス）');
          expect(s.screenName, title, reason: 'GA4 の題の列（スクリーン名）');
        });
      }
    });
  }

  /// **マップは `/map/` を名乗らない。** web に無い URL の形で送ると、web に
  /// いつか `/map/` ができた時に中身の違う 2 つが 1 行に混ざる
  test('web に無い面は /app/ の下に置き、GA4 にはスラッシュの無い名前で送る', () {
    for (final locale in AppLocale.values) {
      final t = AppMessages.of(locale);
      final map = ScreenPath.map(locale, t);
      expect(map.path, '${locale.pathPrefix}/app/map/');
      expect(map.screenClass, isNot(startsWith('/')));
      expect(map.screenName, isNot(startsWith('/')));
    }
  });

  /// **末尾スラッシュを落とさない。** ここが 1 つ違うと GA4 上で別ページになる
  test('すべて / で始まり / で終わり、// を含まない', () {
    for (final locale in AppLocale.values) {
      for (final s in all(locale).values) {
        expect(s.path, endsWith('/'), reason: s.path);
        expect(s.path, startsWith('/'), reason: s.path);
        expect(s.path, isNot(contains('//')), reason: s.path);
      }
    }
  });

  /// **日本語にプレフィックスを付けない。** `/ja/` は web に存在しない
  test('日本語は /ja/ を持たない', () {
    for (final s in all(AppLocale.ja).values) {
      expect(s.path, isNot(startsWith('/ja/')), reason: s.path);
    }
  });

  /// **接尾辞は web と同じ値であること。** ずれると同じ画面が別ページに数えられる
  test('接尾辞が web と同じ', () {
    expect(AppMessages.ja.siteTitleSuffix, 'とん速');
    expect(AppMessages.en.siteTitleSuffix, 'Tonsoku');
    expect(AppMessages.zh.siteTitleSuffix, '豚速');
  });
}
