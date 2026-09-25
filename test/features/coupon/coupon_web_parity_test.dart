import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/coupon/domain/coupon_best_deal.dart';
import 'package:tonsoku/features/coupon/domain/coupon_row.dart';
import 'package:tonsoku/features/coupon/domain/coupon_schedule.dart';
import 'package:tonsoku/shared/models/coupon.dart';

/// クーポンタブの組み立てを **web の実装を実際に走らせた出力**と突き合わせる。
///
/// `test/fixtures/coupon_web_views.json` は tonsoku-frontend-web の
/// `offerRows` / `upcomingRows` / `bestDealView` / `scheduleBars` を `tsx` で
/// 実行し、**戻り値を丸ごと**落としたもの（gyumesy-frontend-app と同じ方式）。
/// 実装した項目だけを抜くと、**実装し忘れた項目が原理的に映らない**
/// （gyumesy でスケジュールの `labelAlign` を移植し忘れたのに一致し続けた）。
///
/// 入力は 2 つ:
///
/// - `coupon_production.json` … とん速の本番（2026-09-25 時点）
/// - `coupon_synthetic.json` … 本番に gyumesy の本番の施策と `best_deal` を
///   足したもの。**とん速の本番はまだ枝が少ない**（決済ブランド・上限・注文例が
///   無い）ので、形が同じ gyumesy の配信で枝を踏ませる。注文例の 1 件は
///   還元・実質・値段を null にしてある（web が `?? null` で受ける経路）
///
/// **作り直す時**（web の組み立てを変えた時）は、web のリポジトリで同じ入力を
/// 読んで 4 関数の戻り値を書き出す（slug と今日の日付は fixture に入っている）。
void main() {
  final fixtures = Directory('test/fixtures');
  final web =
      jsonDecode(
            File('${fixtures.path}/coupon_web_views.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final slugs = (web['slugs'] as List).cast<String>().toSet();
  final today = web['today'] as String;
  final tags =
      (jsonDecode(
                File(
                  '${fixtures.path}/tags_production.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, dynamic>>();
  final tagLabels = {
    for (final tag in tags) tag['slug'] as String: tag['label'] as String,
  };
  final views = (web['views'] as Map).cast<String, Map<String, dynamic>>();

  /// web の URL（`http://localhost:4000/brands/x.webp`）を、アプリが持つ
  /// キー（`brands/x.webp`）に揃える。**アプリは URL にするのを描く側に寄せている**。
  String? keyOf(Object? url) {
    if (url == null) return null;
    final s = url as String;
    final i = s.indexOf('brands/');
    return i < 0 ? s : s.substring(i);
  }

  /// web のバッジ（絵かグリフのどちらか）をアプリの種類に写す。
  CouponBadge? badgeOf(Object? badge) {
    if (badge == null) return null;
    final b = badge as Map<String, dynamic>;
    final image = keyOf(b['imageUrl']);
    if (image != null) {
      return switch (image) {
        'brands/x.webp' => CouponBadge.x,
        'brands/tiktok.webp' => CouponBadge.tiktok,
        _ => throw StateError('知らないバッジの絵: $image'),
      };
    }
    return switch (b['icon']) {
      'smartphone' => CouponBadge.mobileOrder,
      'shopping_bag' => CouponBadge.matsubenNet,
      'sell' => CouponBadge.discount,
      // 配信の絵が無い時のグリフ（`cdnIconUrl` が null の時）
      final Object? other => throw StateError('知らないバッジのグリフ: $other'),
    };
  }

  /// **web の行が持つ鍵をアプリが全部持っているか。** 実装し忘れを捕まえる唯一の網。
  const rowKeys = {
    'id',
    'name',
    'sourceMark',
    'iconUrl',
    'badge',
    'upcoming',
    'primary',
    'capText',
    'terms',
    'period',
    'timeWindow',
    'articleSlug',
    'links',
    'images',
    'startText',
  };
  const imageKeys = {'url', 'label', 'icon', 'isCode', 'source'};
  const partKeys = {'label', 'percent', 'iconUrl', 'noteText'};
  const patternKeys = {'items', 'totalYen', 'backYen', 'netYen'};
  const itemKeys = {'name', 'priceYen', 'articleSlug', 'thumbnail'};
  // `labelAlign` / `labelOffset` は**意図して違う**（web は文字幅を定数で
  // 見積もり、アプリは `TextPainter` で測る）ので値は突き合わせない
  const barKeys = {
    'id',
    'name',
    'value',
    'iconUrl',
    'upcoming',
    'left',
    'width',
    'label',
    'labelAlign',
    'labelOffset',
  };

  void expectRow(CouponRow app, Map<String, dynamic> w, String where) {
    expect(
      w.keys.toSet().difference(rowKeys),
      isEmpty,
      reason: '$where: web にだけある鍵',
    );
    expect(app.id, w['id'], reason: '$where id');
    expect(app.name, w['name'], reason: '$where name');
    expect(app.sourceMark, w['sourceMark'], reason: '$where sourceMark');
    expect(app.iconUrl, keyOf(w['iconUrl']), reason: '$where iconUrl');
    expect(app.badge, badgeOf(w['badge']), reason: '$where badge');
    expect(app.upcoming, w['upcoming'], reason: '$where upcoming');
    expect(app.primary, w['primary'], reason: '$where primary');
    expect(app.capText, w['capText'], reason: '$where capText');
    expect(app.terms, w['terms'], reason: '$where terms');
    expect(app.period, w['period'], reason: '$where period');
    expect(app.timeWindow, w['timeWindow'], reason: '$where timeWindow');
    expect(app.articleSlug, w['articleSlug'], reason: '$where articleSlug');
    expect(app.startText, w['startText'], reason: '$where startText');

    final links = (w['links'] as List).cast<Map<String, dynamic>>();
    expect(
      [for (final l in app.links) (l.url, l.label)],
      [for (final l in links) (l['url'], l['label'])],
      reason: '$where links',
    );

    final images = (w['images'] as List).cast<Map<String, dynamic>>();
    expect(app.images.length, images.length, reason: '$where images');
    for (final (i, image) in images.indexed) {
      expect(
        image.keys.toSet().difference(imageKeys),
        isEmpty,
        reason: '$where images[$i] web にだけある鍵',
      );
      final a = app.images[i];
      final source = image['source'] as Map<String, dynamic>?;
      expect(a.url, image['url'], reason: '$where images[$i].url');
      expect(a.label, image['label'], reason: '$where images[$i].label');
      expect(a.isCode, image['isCode'], reason: '$where images[$i].isCode');
      // 絵は種類で決まる（QR コードだけコードの絵）
      expect(
        image['icon'],
        a.isCode ? 'qr_code_2' : 'zoom_in',
        reason: '$where images[$i].icon',
      );
      expect(
        a.source == null ? null : (a.source!.url, a.source!.label),
        source == null ? null : (source['url'], source['label']),
        reason: '$where images[$i].source',
      );
    }
  }

  for (final entry in views.entries) {
    final [name, localeName] = entry.key.split('/');
    final locale = AppLocale.values.byName(localeName);
    final t = AppMessages.of(locale);
    final w = entry.value;

    group(entry.key, () {
      late Coupon coupon;

      setUpAll(() {
        coupon = Coupon.fromJson(
          jsonDecode(File('${fixtures.path}/$name.json').readAsStringSync())
              as Map<String, dynamic>,
        );
      });

      test('現在使えるクーポン', () {
        final app = offerRows(
          coupon,
          locale: locale,
          t: t,
          tagLabels: tagLabels,
          slugs: slugs,
        );
        final rows = (w['offers'] as List).cast<Map<String, dynamic>>();
        expect(app.length, rows.length);
        for (final (i, row) in rows.indexed) {
          expectRow(app[i], row, 'offers[$i]');
        }
      });

      test('今後の予定', () {
        final app = upcomingRows(
          coupon,
          locale: locale,
          t: t,
          tagLabels: tagLabels,
          slugs: slugs,
        );
        final rows = (w['upcoming'] as List).cast<Map<String, dynamic>>();
        expect(app.length, rows.length);
        for (final (i, row) in rows.indexed) {
          expectRow(app[i], row, 'upcoming[$i]');
        }
      });

      test('最大還元率', () {
        final app = bestDealView(
          coupon: coupon,
          t: t,
          tagLabels: tagLabels,
          slugs: slugs,
        );
        final best = w['best'] as Map<String, dynamic>?;
        if (best == null) {
          expect(app, isNull);
          return;
        }
        expect(app, isNotNull);
        expect(app!.totalPercent, (best['totalPercent'] as num).toDouble());
        expect(app.targetText, best['targetText']);
        expect(app.targetSpendYen, best['targetSpendYen']);

        final parts = (best['parts'] as List).cast<Map<String, dynamic>>();
        expect(app.parts.length, parts.length);
        for (final (i, part) in parts.indexed) {
          expect(part.keys.toSet().difference(partKeys), isEmpty);
          expect(app.parts[i].label, part['label'], reason: 'parts[$i]');
          expect(
            app.parts[i].percent,
            (part['percent'] as num).toDouble(),
            reason: 'parts[$i]',
          );
          expect(app.parts[i].iconKey, keyOf(part['iconUrl']));
          expect(app.parts[i].noteText, part['noteText'], reason: 'parts[$i]');
        }

        final patterns = (best['patterns'] as List)
            .cast<Map<String, dynamic>>();
        expect(app.patterns.length, patterns.length);
        for (final (i, pattern) in patterns.indexed) {
          expect(pattern.keys.toSet().difference(patternKeys), isEmpty);
          final a = app.patterns[i];
          expect(a.totalYen, pattern['totalYen'], reason: 'patterns[$i]');
          expect(a.backYen, pattern['backYen'], reason: 'patterns[$i]');
          expect(a.netYen, pattern['netYen'], reason: 'patterns[$i]');
          final items = (pattern['items'] as List).cast<Map<String, dynamic>>();
          expect(a.items.length, items.length);
          for (final (j, item) in items.indexed) {
            expect(item.keys.toSet().difference(itemKeys), isEmpty);
            expect(a.items[j].name, item['name']);
            expect(a.items[j].priceYen, item['priceYen']);
            expect(a.items[j].articleSlug, item['articleSlug']);
            // web は無い時 null、アプリは空文字（`@Default('')`）
            expect(a.items[j].thumbnail, item['thumbnail'] ?? '');
          }
        }
      });

      test('スケジュール', () {
        final [y, m, d] = today.split('-').map(int.parse).toList();
        final app = buildSchedule(
          coupon: coupon,
          t: t,
          tagLabels: tagLabels,
          formatMonthDay: (iso) => formatMonthDay(iso, locale),
          // JST の正午（日付の境目から離して置く）
          today: DateTime.utc(y, m, d, 3),
          measureLabel: (_) => 0,
        );
        final schedule = w['schedule'] as Map<String, dynamic>;
        expect(app.todayPercent, (schedule['todayPercent'] as num).toDouble());
        expect(app.todayLabel, schedule['todayLabel']);

        final bars = (schedule['bars'] as List).cast<Map<String, dynamic>>();
        expect(app.bars.length, bars.length);
        for (final (i, bar) in bars.indexed) {
          expect(bar.keys.toSet().difference(barKeys), isEmpty);
          final a = app.bars[i];
          expect(a.id, bar['id'], reason: 'bars[$i]');
          expect(a.name, bar['name'], reason: 'bars[$i]');
          expect(a.value, bar['value'], reason: 'bars[$i]');
          expect(a.iconKey, keyOf(bar['iconUrl']), reason: 'bars[$i]');
          expect(a.upcoming, bar['upcoming'], reason: 'bars[$i]');
          expect(a.left, (bar['left'] as num).toDouble(), reason: 'bars[$i]');
          expect(a.width, (bar['width'] as num).toDouble(), reason: 'bars[$i]');
          expect(a.label, bar['label'], reason: 'bars[$i]');
        }
      });
    });
  }
}
