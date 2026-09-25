import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/map/domain/jst.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';

/// 店ごとの品の状態（販売中・発売前・売り切れ・終売）。
void main() {
  final now = parseJst('2026-09-25 12:00')!;

  LimitedMenu menu({
    String id = 'm',
    String? start = '2026-09-23 15:00',
    List<String> shops = const [],
    List<String> soldOut = const [],
    List<EndedShop> ended = const [],
    String? endedAt,
  }) => LimitedMenu(
    campaignId: id,
    name: id,
    startDate: start,
    shops: shops,
    soldOutShops: soldOut,
    endedShops: ended,
    endedAt: endedAt,
  );

  test('販売中・売り切れ', () {
    final m = menu(shops: ['a', 'b'], soldOut: ['b']);
    expect(
      availabilityAt(m, 'a', now: now)?.availability,
      LimitedAvailability.selling,
    );
    expect(
      availabilityAt(m, 'b', now: now)?.availability,
      LimitedAvailability.soldOut,
    );
    expect(availabilityAt(m, 'c', now: now), isNull);
  });

  test('発売前は発売の時刻を持つ', () {
    final m = menu(start: '2026-09-30 15:00', shops: ['a']);
    final a = availabilityAt(m, 'a', now: now)!;
    expect(a.availability, LimitedAvailability.upcoming);
    expect(a.at, parseJst('2026-09-30 15:00'));
    // 発売の時刻をまたげば販売中（時刻を焼き付けない）
    expect(
      availabilityAt(m, 'a', now: parseJst('2026-09-30 15:00'))?.availability,
      LimitedAvailability.selling,
    );
  });

  test('終売は店ごとの時刻を持つ', () {
    final m = menu(
      ended: [const EndedShop(code: 'a', endedAt: '2026-09-19 08:01')],
      endedAt: '2026-09-23 15:16',
    );
    final a = availabilityAt(m, 'a', now: now)!;
    expect(a.availability, LimitedAvailability.ended);
    expect(a.at, parseJst('2026-09-19 08:01'));
    expect(a.dateOnly, isFalse);
  });

  test('店ごとの時刻が読めなければ全店の終売に落とす（日付だけのこともある）', () {
    final m = menu(
      ended: [const EndedShop(code: 'a', endedAt: '')],
      endedAt: '2026-09-23',
    );
    final a = availabilityAt(m, 'a', now: now)!;
    expect(a.availability, LimitedAvailability.ended);
    expect(a.at, parseJst('2026-09-23'));
    expect(a.dateOnly, isTrue);
  });

  test('掲載に戻った店は終売より「いま」を採る', () {
    final m = menu(
      shops: ['a'],
      ended: [const EndedShop(code: 'a', endedAt: '2026-09-19 08:01')],
    );
    expect(
      availabilityAt(m, 'a', now: now)?.availability,
      LimitedAvailability.selling,
    );
  });

  test('索引は掲載中と終売の両方の店から引ける', () {
    final index = LimitedIndex([
      menu(id: 'x', shops: ['a']),
      menu(
        id: 'y',
        ended: [const EndedShop(code: 'a', endedAt: '2026-09-19 08:01')],
      ),
    ]);
    final at = index.at('a', now: now);
    expect([for (final e in at) e.menu.campaignId], ['x', 'y']);
    expect(strongest(at), LimitedAvailability.selling);
    expect(index.at('zzz', now: now), isEmpty);
    expect(strongest(const []), isNull);
  });

  test('強さの並び: 販売中 > 発売前 > 売り切れ > 終売', () {
    expect(LimitedAvailability.values, [
      LimitedAvailability.selling,
      LimitedAvailability.upcoming,
      LimitedAvailability.soldOut,
      LimitedAvailability.ended,
    ]);
  });
}
