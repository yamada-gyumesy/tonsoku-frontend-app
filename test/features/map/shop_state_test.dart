import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/domain/jst.dart';
import 'package:tonsoku/features/map/domain/shop_state.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 店のいまの状態。**牛めしレーダーの `Shop.isOpen` の判定を写したもの**に、
/// `temp_closed`（カレンダーの一時閉店）と JST の読み方を足してある。
void main() {
  Shop shop({String? closing, String? opening, TempClosed? temp}) => Shop(
    code: '1',
    name: '松のや テスト店',
    lat: 35,
    lon: 139,
    closingDate: closing,
    openingDate: opening,
    tempClosed: temp,
  );

  /// JST の壁時計で「いま」を作る。
  DateTime at(String jst) => parseJst(jst)!;

  group('JST で読む', () {
    test('時刻つき・日付だけ', () {
      expect(parseJst('2026-09-23 15:00'), DateTime.utc(2026, 9, 23, 6));
      expect(parseJst('2026-09-23'), DateTime.utc(2026, 9, 22, 15));
      expect(parseJst('not a date'), isNull);
      expect(parseJst(null), isNull);
    });

    test('端末のタイムゾーンに関係なく同じ瞬間', () {
      // 15:00 JST は 06:00 UTC。**DateTime.parse に渡すと端末の時刻で読まれる**
      expect(parseJst('2026-09-23 15:00')!.isUtc, isTrue);
      expect(toJstWall(parseJst('2026-09-23 15:00')!).hour, 15);
    });
  });

  group('閉店日・開店日（レーダーと同じ判定）', () {
    test('どちらも無ければ営業中', () {
      expect(shopStateOf(shop(), now: at('2026-09-25 12:00')), isA<ShopOpen>());
    });

    test('改装（閉店 → 開店）: 区間の中は一時閉店、外は営業中', () {
      final s = shop(closing: '2026-09-24 15:00', opening: '2026-10-02 15:00');
      final before = shopStateOf(s, now: at('2026-09-20 12:00'));
      expect(before, isA<ShopOpen>());
      // 改装の予定（閉店の後に再開が控えている。閉店の予定と取り違えない）
      expect((before as ShopOpen).closingAt, at('2026-09-24 15:00'));
      expect(before.reopensAt, at('2026-10-02 15:00'));

      final during = shopStateOf(s, now: at('2026-09-25 12:00'));
      expect(during, isA<ShopTemporarilyClosed>());
      expect(
        (during as ShopTemporarilyClosed).reopensAt,
        at('2026-10-02 15:00'),
      );

      expect(shopStateOf(s, now: at('2026-10-03 12:00')), isA<ShopOpen>());
    });

    test('新店（開店 → 閉店）: 区間の内外が逆になる', () {
      final s = shop(opening: '2026-10-01 10:00', closing: '2027-01-01 10:00');
      expect(
        shopStateOf(s, now: at('2026-09-25 12:00')),
        isA<ShopNotYetOpen>(),
      );
      expect(shopStateOf(s, now: at('2026-11-01 12:00')), isA<ShopOpen>());
      expect(shopStateOf(s, now: at('2027-02-01 12:00')), isA<ShopClosed>());
    });

    test('開店日だけ（新店）', () {
      final s = shop(opening: '2026-10-01 10:00');
      final state = shopStateOf(s, now: at('2026-09-25 12:00'));
      expect(state, isA<ShopNotYetOpen>());
      expect((state as ShopNotYetOpen).opensAt, at('2026-10-01 10:00'));
      expect(shopStateOf(s, now: at('2026-10-01 10:00')), isA<ShopOpen>());
    });

    test('閉店日だけ: 過ぎたら閉店', () {
      final s = shop(closing: '2026-09-30 22:00');
      final open = shopStateOf(s, now: at('2026-09-30 21:59'));
      expect((open as ShopOpen).closingAt, at('2026-09-30 22:00'));
      expect(open.reopensAt, isNull);
      expect(shopStateOf(s, now: at('2026-09-30 22:00')), isA<ShopClosed>());
    });
  });

  group('一時閉店（temp_closed）', () {
    const temp = TempClosed(startDate: '2026-09-06', endDate: '2026-09-28');

    test('期間の中は一時閉店（再開日つき）', () {
      final state = shopStateOf(shop(temp: temp), now: at('2026-09-25 12:00'));
      expect(state, isA<ShopTemporarilyClosed>());
      expect((state as ShopTemporarilyClosed).until, '2026-09-28');
    });

    test('再開日の朝からは営業中', () {
      expect(
        shopStateOf(shop(temp: temp), now: at('2026-09-28 00:00')),
        isA<ShopOpen>(),
      );
    });

    test('これからの一時閉店は営業中の店に添える', () {
      final state = shopStateOf(
        shop(temp: const TempClosed(startDate: '2026-10-04', endDate: null)),
        now: at('2026-09-25 12:00'),
      );
      expect(state, isA<ShopOpen>());
      expect((state as ShopOpen).tempClosedFrom, '2026-10-04');
      expect(state.tempClosedUntil, isNull);
    });

    test('再開日未定', () {
      final state = shopStateOf(
        shop(temp: const TempClosed(startDate: '2026-09-01', endDate: null)),
        now: at('2026-09-25 12:00'),
      );
      expect(state, isA<ShopTemporarilyClosed>());
      expect((state as ShopTemporarilyClosed).until, isNull);
      expect(state.reopensAt, isNull);
    });

    test('閉店日・開店日より temp_closed を先に見る（本番の梅田店の形）', () {
      final state = shopStateOf(
        shop(
          closing: '2026-09-06 15:00',
          opening: '2026-09-28 15:00',
          temp: temp,
        ),
        now: at('2026-09-25 12:00'),
      );
      expect((state as ShopTemporarilyClosed).until, '2026-09-28');
    });

    test('一時閉店の初日は closing_date の時刻まで営業（本番の幕張インター店の形）', () {
      final makuhari = shop(
        closing: '2026-10-04 15:00',
        opening: '2026-10-09 15:00',
        temp: const TempClosed(startDate: '2026-10-04', endDate: '2026-10-09'),
      );
      final morning = shopStateOf(makuhari, now: at('2026-10-04 09:00'));
      expect(morning, isA<ShopOpen>());
      // これからの一時閉店として添える
      expect((morning as ShopOpen).tempClosedFrom, '2026-10-04');
      expect(
        shopStateOf(makuhari, now: at('2026-10-04 15:00')),
        isA<ShopTemporarilyClosed>(),
      );
      // 再開日は opening_date の時刻から
      expect(
        shopStateOf(makuhari, now: at('2026-10-09 09:00')),
        isA<ShopTemporarilyClosed>(),
      );
      expect(
        shopStateOf(makuhari, now: at('2026-10-09 15:00')),
        isA<ShopOpen>(),
      );
    });
  });
}
