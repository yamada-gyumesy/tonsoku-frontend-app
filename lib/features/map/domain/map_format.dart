import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/features/map/domain/jst.dart';
import 'package:tonsoku/features/map/domain/limited_status.dart';
import 'package:tonsoku/features/map/domain/shop_filter.dart';
import 'package:tonsoku/features/map/domain/shop_state.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 瞬間を JST の「月/日 時」で出す。**年は出さない**（扱うのは前後 2 週間ほどの
/// 出来事だけ。記事の取扱店の表と同じ）。
String formatWhen(DateTime instant, AppMessages t, {bool dateOnly = false}) {
  final w = toJstWall(instant);
  return dateOnly
      ? t.mapDate(w.month, w.day)
      : t.mapDateTime(w.month, w.day, w.hour, w.minute);
}

/// `YYYY-MM-DD`（一時閉店の期間）を「月/日」で出す。**タイムゾーンを通さない**
/// （日付そのものなので、瞬間に直すと海外の端末で前日にずれる）。
String formatDay(String date, AppMessages t) {
  final parts = date.split('-');
  if (parts.length != 3) return date;
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (m == null || d == null) return date;
  return t.mapDate(m, d);
}

/// 画面に出す店名。**[Shop.name] が null（英語・中国語で訳がまだ無い）なら
/// ローマ字名（`NISHISHINJUKU`）で代える**（日本語に落とさない。配信側のスキーマが
/// 「name_roman に落とせる」としている。tonsoku-backend-batch#286）。
///
/// ローマ字名は大文字のまま出す（組み替えない。語の切れ目が分からないので、
/// 頭だけ大文字にすると `Nishishinjuku` のような存在しない綴りになる）。
/// **どちらも無ければ null**（名前の欄を描かない）。
String? shopLabel(Shop shop) => shop.name ?? shop.nameRoman;

String brandLabel(ShopBrand brand, AppMessages t) => switch (brand) {
  ShopBrand.matsuya => t.mapBrandMatsuya,
  ShopBrand.mycurry => t.mapBrandMycurry,
};

/// 品の状態の名前（時刻を添えない。品のチップの内訳）。
String availabilityName(LimitedAvailability a, AppMessages t) => switch (a) {
  LimitedAvailability.selling => t.mapSelling,
  LimitedAvailability.upcoming => t.mapUpcoming,
  LimitedAvailability.soldOut => t.mapSoldOut,
  LimitedAvailability.ended => t.homeLimitedEnded,
};

/// 品の状態の短い札（店の詳細の各行）。**終売・発売前は時刻を添える。**
String availabilityLabel(ShopLimited item, AppMessages t) {
  final at = item.at;
  return switch (item.availability) {
    LimitedAvailability.selling => t.mapSelling,
    LimitedAvailability.soldOut => t.mapSoldOut,
    LimitedAvailability.upcoming =>
      at == null ? t.mapUpcoming : t.mapStartsAt(formatWhen(at, t)),
    LimitedAvailability.ended =>
      at == null
          ? t.homeLimitedEnded
          : t.mapEndedAt(formatWhen(at, t, dateOnly: item.dateOnly)),
  };
}

/// 店の状態の一文（店の詳細の上に出す）。**営業していて予定も無ければ null**
/// （「営業中」とは書かない。営業時間の表記と食い違って見えるため）。
String? shopNotice(ShopState state, AppMessages t) => switch (state) {
  ShopOpen(tempClosedFrom: final from?, :final tempClosedUntil) =>
    t.mapTempClosedPlanned(
      formatDay(from, t),
      tempClosedUntil == null ? null : formatDay(tempClosedUntil, t),
    ),
  ShopOpen(closingAt: final closing?, reopensAt: final reopens?) =>
    t.mapTempClosedPlanned(formatWhen(closing, t), formatWhen(reopens, t)),
  ShopOpen(closingAt: final closing?) => t.mapClosesAt(formatWhen(closing, t)),
  ShopOpen() => null,
  ShopTemporarilyClosed(until: final until?) => t.mapTempClosedUntil(
    formatDay(until, t),
  ),
  ShopTemporarilyClosed(reopensAt: final reopens?) => t.mapTempClosedUntil(
    formatWhen(reopens, t),
  ),
  ShopTemporarilyClosed() => t.mapTempClosed,
  ShopNotYetOpen(:final opensAt) => t.mapOpensAt(formatWhen(opensAt, t)),
  ShopClosed() => t.mapClosed,
};
