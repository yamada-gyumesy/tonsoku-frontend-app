import 'package:tonsoku/features/map/domain/jst.dart';
import 'package:tonsoku/shared/models/limited_menu.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 地図の印が**時刻だけで**次に変わる瞬間（[now] より後で一番早いもの）。
/// 無ければ null。
///
/// 印と店の詳細は画面を組む時の時刻で決まる（`shopStateOf` / `availabilityAt`）ので、
/// 時間が経つだけでは描き直されない。マップはこの時刻に組み直す（`MapPage`）。
///
/// 数えるのは、品の発売（`start_date`）と、店の閉店・開店・一時閉店の出入り
/// （`closing_date` / `opening_date` / `temp_closed`）。一時閉店の日付は 0:00 で
/// 数える ―― 実際の起点が同じ日の閉店時刻でも、そちらも別に数えているので
/// 取りこぼさない（早めに 1 回余計に組み直すだけ）。
DateTime? nextChangeAfter(
  DateTime now,
  Iterable<Shop> shops,
  Iterable<LimitedMenu> menus,
) {
  DateTime? best;
  void consider(String? value) {
    final t = parseJst(value);
    if (t == null || !t.isAfter(now)) return;
    if (best == null || t.isBefore(best!)) best = t;
  }

  for (final m in menus) {
    consider(m.startDate);
  }
  for (final s in shops) {
    consider(s.closingDate);
    consider(s.openingDate);
    consider(s.tempClosed?.startDate);
    consider(s.tempClosed?.endDate);
  }
  return best;
}
