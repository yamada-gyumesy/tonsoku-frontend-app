import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/features/map/domain/jst.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/domain/shop_state.dart';
import 'package:tonsoku/features/map/presentation/widgets/shop_sheet.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 店の詳細。**rader より情報を増やした**（住所・営業時間・電話・一時閉店・
/// Google マップ）ことと、店舗限定の状態が読めることを見る。
void main() {
  const shop = Shop(
    code: '0000001203',
    name: '松のや 津田沼南口店',
    lat: 35.69,
    lon: 140.01,
    brands: ['mycurry', 'matsuya', 'matsunoya'],
    address: '千葉県習志野市谷津7-9-16',
    businessHours: '5時から翌2時、ラストオーダー30分前',
    phone: '080-5928-1179',
  );

  Future<void> pump(
    WidgetTester tester, {
    Shop? target,
    ShopState state = const ShopOpen(),
    List<ShopLimited> limited = const [],
    ValueChanged<String>? onOpenArticle,
  }) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'ja'});
    final store = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(store)],
        child: MaterialApp(
          theme: AppTheme.light(AppLocale.ja),
          home: Scaffold(
            body: ShopSheet(
              shop: target ?? shop,
              state: state,
              limited: limited,
              onOpenArticle: onOpenArticle ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('店名・併設・住所・営業時間・電話・Google マップ', (tester) async {
    await pump(tester);
    expect(find.text('松のや 津田沼南口店'), findsOneWidget);
    // 併設は並びを固定（松屋が先）。松のや自身は出さない
    expect(find.text('松屋併設'), findsOneWidget);
    expect(find.text('マイカリー食堂併設'), findsOneWidget);
    expect(find.textContaining('松のや併設'), findsNothing);
    expect(find.text('千葉県習志野市谷津7-9-16'), findsOneWidget);
    expect(find.text('住所'), findsOneWidget);
    expect(find.text('営業時間'), findsOneWidget);
    expect(find.text('5時から翌2時、ラストオーダー30分前'), findsOneWidget);
    expect(find.text('080-5928-1179'), findsOneWidget);
    expect(find.bySemanticsLabel('080-5928-1179 に電話をかける'), findsOneWidget);
    expect(find.text('Google マップで開く'), findsOneWidget);
    // 営業中で予定も無ければ一文は出さない
    expect(find.textContaining('閉店'), findsNothing);
  });

  testWidgets('一時閉店の一文', (tester) async {
    await pump(tester, state: const ShopTemporarilyClosed(until: '2026-09-28'));
    expect(find.text('一時閉店中（9/28 再開）'), findsOneWidget);
  });

  testWidgets('店舗限定は強い順に、状態と時刻つきで並ぶ。記事があれば開ける', (tester) async {
    String? opened;
    await pump(
      tester,
      onOpenArticle: (slug) => opened = slug,
      limited: [
        ShopLimited(
          menu: const LimitedMenu(
            campaignId: '174161',
            name: '“極厚”肩ロース定食',
            articleSlug: '2cjtbt',
          ),
          availability: LimitedAvailability.ended,
          at: parseJst('2026-09-19 08:01'),
        ),
        const ShopLimited(
          menu: LimitedMenu(campaignId: 'b', name: '売り切れの品'),
          availability: LimitedAvailability.soldOut,
        ),
        const ShopLimited(
          menu: LimitedMenu(
            campaignId: '177979',
            name: 'たっぷりねぎと味噌ダレの超厚切りリブロースかつ定食',
            articleSlug: 'lsmujz',
          ),
          availability: LimitedAvailability.selling,
        ),
      ],
    );

    expect(find.text('店舗限定'), findsOneWidget);
    expect(find.text('販売中'), findsOneWidget);
    expect(find.text('売り切れ'), findsOneWidget);
    expect(find.text('9/19 8時 終売'), findsOneWidget);

    // 販売中が一番上
    final selling = tester.getTopLeft(find.text('たっぷりねぎと味噌ダレの超厚切りリブロースかつ定食'));
    final ended = tester.getTopLeft(find.text('“極厚”肩ロース定食'));
    expect(selling.dy, lessThan(ended.dy));

    await tester.tap(find.text('“極厚”肩ロース定食'));
    expect(opened, '2cjtbt');
  });

  /// 英語・中国語の面は訳の無い店名・住所・営業時間が null
  /// （tonsoku-backend-batch#286）。**日本語に落とさない。**
  testWidgets('店名が null ならローマ字名、住所・営業時間が null なら行を出さない', (tester) async {
    await pump(
      tester,
      target: const Shop(
        code: '0000001203',
        nameRoman: 'TSUDANUMAMINAMIGUCHI',
        lat: 35.69,
        lon: 140.01,
        phone: '080-5928-1179',
      ),
    );
    expect(find.text('TSUDANUMAMINAMIGUCHI'), findsOneWidget);
    expect(find.text('住所'), findsNothing);
    expect(find.text('営業時間'), findsNothing);
    expect(find.text('080-5928-1179'), findsOneWidget);
  });

  testWidgets('店名もローマ字名も無ければ名前の欄を描かない', (tester) async {
    await pump(
      tester,
      target: const Shop(code: '0000001203', lat: 35.69, lon: 140.01),
    );
    expect(find.text('Google マップで開く'), findsOneWidget);
    expect(find.text('null'), findsNothing);
  });
}
