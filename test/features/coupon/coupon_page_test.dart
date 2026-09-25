import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/coupon/data/coupon_repository.dart';
import 'package:tonsoku/features/coupon/presentation/coupon_page.dart';
import 'package:tonsoku/features/coupon/presentation/widgets/coupon_best_card.dart';
import 'package:tonsoku/features/coupon/presentation/widgets/coupon_list.dart';
import 'package:tonsoku/features/coupon/presentation/widgets/coupon_schedule_chart.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/coupon.dart';
import 'package:tonsoku/shared/models/tag.dart';

/// クーポンタブ。web の `coupon.astro` と同じく、**節ごと出す／出さないの判断が
/// 要件**なので、そこを固定する（行の中身は `coupon_web_parity_test.dart` が
/// web の出力と突き合わせている）。
void main() {
  final t = AppMessages.ja;
  late Coupon production;
  late Coupon synthetic;
  late List<Tag> tags;

  Coupon load(String name) => Coupon.fromJson(
    jsonDecode(File('test/fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  setUpAll(() {
    production = load('coupon_production');
    synthetic = load('coupon_synthetic');
    tags = [
      for (final tag
          in (jsonDecode(
                    File(
                      'test/fixtures/tags_production.json',
                    ).readAsStringSync(),
                  )
                  as List)
              .cast<Map<String, dynamic>>())
        Tag.fromJson(tag),
    ];
  });

  Future<void> pump(
    WidgetTester tester,
    Coupon? coupon, {
    bool dark = false,
    ValueChanged<String>? onOpenCalendar,
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(store),
          couponProvider.overrideWith((ref) => Stream.value(coupon)),
          tagsProvider.overrideWith((ref) => Stream.value(tags)),
          articleIndexProvider.overrideWith(
            (ref) => Stream.value(const <ArticleMeta>[]),
          ),
          feedProvider.overrideWith(
            (ref) => Stream.value(const <ArticleMeta>[]),
          ),
        ],
        child: MaterialApp(
          theme: dark
              ? AppTheme.dark(AppLocale.ja)
              : AppTheme.light(AppLocale.ja),
          home: CouponPage(
            onOpenArticle: (_) {},
            onOpenCalendar: onOpenCalendar ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// 配信の時刻（`generated_at`）の日に固定する。スケジュールの帯は今日の前後の
  /// 窓に入るものだけなので、実時間で走らせると日によって結果が変わる。
  T atGeneratedAt<T>(Coupon coupon, T Function() body) =>
      withClock(Clock.fixed(DateTime.parse(coupon.generatedAt)), body);

  testWidgets('全部の節が揃う配信では 4 節とも出る', (tester) async {
    await atGeneratedAt(synthetic, () async {
      await pump(tester, synthetic);

      expect(find.text(t.couponPageTitle), findsOneWidget);
      expect(find.text(t.couponDisclaimer), findsOneWidget);
      expect(find.text(t.couponTypesHeading), findsOneWidget);
      expect(find.text(t.couponOffersHeading), findsOneWidget);
      expect(find.text(t.couponBestHeading), findsOneWidget);
      expect(find.text(t.couponUpcomingHeading), findsOneWidget);
      expect(find.text(t.couponScheduleHeading), findsOneWidget);
      expect(find.byType(CouponList), findsNWidgets(2));
      expect(find.byType(CouponBestCard), findsOneWidget);
      expect(find.byType(CouponScheduleChart), findsOneWidget);
    });
  });

  /// web の `coupon.astro` と同じく、スケジュールの見出しの右から
  /// **キャンペーンで絞った**カレンダーへ（web は `#category=campaign`）。
  testWidgets('スケジュールの見出しからキャンペーンで絞ったカレンダーを開く', (tester) async {
    await atGeneratedAt(synthetic, () async {
      final opened = <String>[];
      await pump(tester, synthetic, onOpenCalendar: opened.add);

      final link = find.text(t.calendarViewCalendar);
      expect(link, findsOneWidget);
      // 見出しの行に置く（見出しと同じ高さの帯の中）
      expect(
        (tester.getCenter(link).dy -
                tester.getCenter(find.text(t.couponScheduleHeading)).dy)
            .abs(),
        lessThan(12),
      );

      await tester.ensureVisible(link);
      await tester.pumpAndSettle();
      await tester.tap(link);
      expect(opened, ['campaign']);
    });
  });

  testWidgets('スケジュールが出ない日は導線も出ない', (tester) async {
    await pump(tester, null);
    expect(find.text(t.calendarViewCalendar), findsNothing);
  });

  testWidgets('時点は一覧の見出しに日付まで添える', (tester) async {
    await atGeneratedAt(production, () async {
      await pump(tester, production);
      expect(find.text('2026年9月25日 時点'), findsOneWidget);
    });
  });

  /// **配布元の印は名前と同じ 1 つの文字列**（分けると幅の狭い端末で印だけが
  /// 残って名前が消える。web の実測）。
  testWidgets('配布元の印は名前と 1 つの文字列で出す', (tester) async {
    await atGeneratedAt(production, () async {
      await pump(tester, production);
      expect(find.text('【TikTok】食欲の秋'), findsOneWidget);
      expect(find.text('【X】秋の丼祭り'), findsOneWidget);
    });
  });

  /// **QR コードを先に出す**（券売機の前で押すのはこちら）。
  testWidgets('QR コードのチップは詳細画像より前に並ぶ', (tester) async {
    await atGeneratedAt(production, () async {
      await pump(tester, production);
      final qr = tester.getTopLeft(find.text(t.couponQrImage).first);
      final flyer = tester.getTopLeft(find.text(t.couponDetailImage).first);
      // 読む順で前（同じ行なら左、折り返したなら上の行）。テストの字形は
      // 幅が広く、チップが折り返すことがある
      expect(
        qr.dy < flyer.dy || (qr.dy == flyer.dy && qr.dx < flyer.dx),
        isTrue,
        reason: 'QR $qr / 詳細画像 $flyer',
      );
    });
  });

  /// **今後の予定が 0 件の日は節ごと出さない**（見出しと「ありません」だけが
  /// 残るのは情報にならない）。現在使えるクーポンは空でも残す（別のテスト）。
  testWidgets('今後の予定が無い日は節ごと出さない', (tester) async {
    await atGeneratedAt(production, () async {
      expect(production.upcoming, isEmpty, reason: '前提: 本番は予定が 0 件');
      await pump(tester, production);
      expect(find.text(t.couponUpcomingHeading), findsNothing);
      expect(find.byType(CouponList), findsOneWidget);
    });
  });

  testWidgets('今後の予定は開始日を名前の前に出す', (tester) async {
    await atGeneratedAt(synthetic, () async {
      await pump(tester, synthetic);
      // 合成の予定は 8/25 開始と 10/5 開始
      expect(find.text('[8/25]'), findsOneWidget);
      expect(find.text('[10/5]'), findsOneWidget);
    });
  });

  /// **配信が無い（`coupon.json` がまだ無い）日は、空の一覧だけを出す。**
  /// 「現在使えるクーポン」は空でも節を残す（空＝今日使えるものが無い、という
  /// 情報そのもの）。
  testWidgets('配信が無い日は「ありません」だけを出す', (tester) async {
    await pump(tester, null);
    expect(find.text(t.couponOffersHeading), findsOneWidget);
    expect(find.text(t.couponOffersEmpty), findsOneWidget);
    expect(find.text(t.couponBestHeading), findsNothing);
    expect(find.text(t.couponUpcomingHeading), findsNothing);
    expect(find.text(t.couponScheduleHeading), findsNothing);
  });

  /// 注文例の還元・実質は**配信が出している時だけ**（web の `?? null`）。
  /// 合成の最後の注文例は両方 null にしてある。
  testWidgets('還元の無い注文例は金額の行を合計だけにする', (tester) async {
    await atGeneratedAt(synthetic, () async {
      await pump(tester, synthetic);
      final patterns = synthetic.bestDeal!.patterns;
      expect(patterns.last.backYen, isNull, reason: '前提');
      // 還元の行は、還元を持つ注文例の数だけ
      final withBack = patterns.where((p) => p.backYen != null).length;
      expect(
        find.textContaining('${t.couponBackLabel} ', findRichText: true),
        findsNWidgets(withBack),
      );
    });
  });

  testWidgets('ダークでも崩れずに組める', (tester) async {
    await atGeneratedAt(synthetic, () async {
      await pump(tester, synthetic, dark: true);
      expect(find.byType(CouponBestCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
