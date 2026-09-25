import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/config/app_config.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';

void main() {
  const config = AppConfig(
    cdnBaseUrl: 'https://cdn.ton-soku.com',
    siteBaseUrl: 'https://ton-soku.com',
  );

  group('cdnUrl', () {
    test('絶対 URL はそのまま返す', () {
      // 配信データの thumbnail は絶対 URL で入っている（gyumesy の本番 feed.json は 192/200 件。とん速も同じ形）
      const absolute =
          'https://cdn.ton-soku.com/articles/abc/thumbnail-sm.webp';
      expect(config.cdnUrl(absolute), absolute);
      expect(
        config.cdnUrl('http://localhost:4000/x.webp'),
        'http://localhost:4000/x.webp',
      );
    });

    test('相対パスは CDN のベースに繋ぐ', () {
      expect(
        config.cdnUrl('articles/abc/thumbnail.webp'),
        'https://cdn.ton-soku.com/articles/abc/thumbnail.webp',
      );
    });

    test('先頭スラッシュの有無で二重スラッシュにならない', () {
      expect(
        config.cdnUrl('/articles/abc/thumbnail.webp'),
        'https://cdn.ton-soku.com/articles/abc/thumbnail.webp',
      );
    });
  });

  group('siteUrl', () {
    test('日本語はルート直下（/ja/ にしない）', () {
      expect(
        config.siteUrl('/articles/abc/', AppLocale.ja),
        'https://ton-soku.com/articles/abc/',
      );
    });

    test('追加ロケールはパスプレフィックス付き', () {
      expect(
        config.siteUrl('/articles/abc/', AppLocale.en),
        'https://ton-soku.com/en/articles/abc/',
      );
      expect(
        config.siteUrl('/coupon/', AppLocale.zh),
        'https://ton-soku.com/zh/coupon/',
      );
    });
  });
}
