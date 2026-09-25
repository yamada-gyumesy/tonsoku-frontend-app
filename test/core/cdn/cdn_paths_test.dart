import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/cdn/cdn_paths.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';

void main() {
  group('日本語はルート直下', () {
    const paths = CdnPaths(AppLocale.ja);

    test('一覧系に名前空間が付かない', () {
      expect(paths.feed, 'articles/feed.json');
      expect(paths.categories, 'categories.json');
      expect(paths.calendar, 'calendar.json');
      expect(paths.ranking, 'ranking.json');
      expect(paths.coupon, 'coupon.json');
      expect(paths.limitedWeeks, 'limited/weeks.json');
      expect(paths.categoryArticles('menu'), 'categories/menu/articles.json');
    });

    test('記事本体は articles/{slug}.json', () {
      expect(paths.article('5723kr'), 'articles/5723kr.json');
    });
  });

  group('追加ロケールは i18n/{locale}/ 配下', () {
    const paths = CdnPaths(AppLocale.en);

    test('一覧系に名前空間が付く', () {
      expect(paths.feed, 'i18n/en/articles/feed.json');
      expect(paths.categories, 'i18n/en/categories.json');
      expect(paths.coupon, 'i18n/en/coupon.json');
      expect(paths.limitedWeeks, 'i18n/en/limited/weeks.json');
      expect(
        paths.categoryArticles('menu'),
        'i18n/en/categories/menu/articles.json',
      );
    });

    test('記事本体も名前空間に従う（gyumesy の md の例外は無い）', () {
      expect(paths.article('5723kr'), 'i18n/en/articles/5723kr.json');
      expect(
        const CdnPaths(AppLocale.zh).article('5723kr'),
        'i18n/zh/articles/5723kr.json',
      );
    });
  });
}
