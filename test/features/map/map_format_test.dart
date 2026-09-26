import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/features/map/domain/jst.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/domain/map_format.dart';
import 'package:tonsoku/features/map/domain/shop_state.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/shared/models/shop.dart';

void main() {
  final ja = AppMessages.ja;
  final en = AppMessages.en;
  const menu = LimitedMenu(campaignId: 'x', name: 'x');

  test('終売の時刻は JST の「月/日 時」（記事の取扱店の表と同じ粒度）', () {
    final item = ShopLimited(
      menu: menu,
      availability: LimitedAvailability.ended,
      at: parseJst('2026-09-19 08:01'),
    );
    expect(availabilityLabel(item, ja), '9/19 8時 終売');
    // 英語は分まで（丸めたことが読めなくなるので :00 にしない）
    expect(availabilityLabel(item, en), 'Ended 9/19 8:01');
  });

  test('日付だけの終売は時刻を出さない', () {
    final item = ShopLimited(
      menu: menu,
      availability: LimitedAvailability.ended,
      at: parseJst('2026-09-23'),
      dateOnly: true,
    );
    expect(availabilityLabel(item, ja), '9/23 終売');
  });

  test('時刻の分からない終売・販売中・売り切れ・発売前', () {
    expect(
      availabilityLabel(
        const ShopLimited(menu: menu, availability: LimitedAvailability.ended),
        ja,
      ),
      '終売',
    );
    expect(
      availabilityLabel(
        const ShopLimited(
          menu: menu,
          availability: LimitedAvailability.selling,
        ),
        ja,
      ),
      '販売中',
    );
    expect(
      availabilityLabel(
        const ShopLimited(
          menu: menu,
          availability: LimitedAvailability.soldOut,
        ),
        ja,
      ),
      '売り切れ',
    );
    expect(
      availabilityLabel(
        ShopLimited(
          menu: menu,
          availability: LimitedAvailability.upcoming,
          at: parseJst('2026-09-30 15:00'),
        ),
        ja,
      ),
      '9/30 15時 発売',
    );
  });

  test('店の状態の一文', () {
    expect(shopNotice(const ShopOpen(), ja), isNull);
    expect(
      shopNotice(const ShopTemporarilyClosed(until: '2026-09-28'), ja),
      '一時閉店中（9/28 再開）',
    );
    expect(shopNotice(const ShopTemporarilyClosed(), ja), '一時閉店中（再開日未定）');
    expect(
      shopNotice(
        const ShopOpen(
          tempClosedFrom: '2026-10-04',
          tempClosedUntil: '2026-10-09',
        ),
        ja,
      ),
      '10/4〜10/9 一時閉店',
    );
    expect(
      shopNotice(const ShopOpen(tempClosedFrom: '2026-10-04'), ja),
      '10/4 から一時閉店',
    );
    expect(
      shopNotice(ShopNotYetOpen(parseJst('2026-10-01 10:00')!), ja),
      '10/1 10時 開店',
    );
    expect(
      shopNotice(
        ShopOpen(
          closingAt: parseJst('2026-09-24 15:00'),
          reopensAt: parseJst('2026-10-02 15:00'),
        ),
        ja,
      ),
      '9/24 15時〜10/2 15時 一時閉店',
    );
    expect(
      shopNotice(ShopOpen(closingAt: parseJst('2026-09-30 22:00')), ja),
      '9/30 22時 閉店',
    );
    expect(shopNotice(const ShopClosed(), ja), '閉店');
  });

  group('shopLabel', () {
    test('店名があれば店名', () {
      const shop = Shop(
        code: '1',
        name: 'Matsunoya Nishi-Shinjuku',
        nameRoman: 'NISHISHINJUKU',
        lat: 35,
        lon: 139,
      );
      expect(shopLabel(shop), 'Matsunoya Nishi-Shinjuku');
    });

    test('店名が null（訳が無い）ならローマ字名、それも無ければ null', () {
      const roman = Shop(
        code: '1',
        nameRoman: 'NISHISHINJUKU',
        lat: 35,
        lon: 139,
      );
      expect(shopLabel(roman), 'NISHISHINJUKU');
      expect(shopLabel(const Shop(code: '1', lat: 35, lon: 139)), isNull);
    });
  });
}
