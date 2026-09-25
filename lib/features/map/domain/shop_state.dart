import 'package:clock/clock.dart';

import 'package:tonsoku/features/map/domain/jst.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 店のいまの状態。**時刻で変わるので、provider に結果を持たせないこと**
/// （牛めしレーダーの `shopLimitedMenuMapProvider` の注記と同じ理由。キャッシュに
/// 判定が焼き付くと、開いたまま開店・閉店の時刻をまたいでも変わらない）。
/// 画面を組むたびに [shopStateOf] で求める。
sealed class ShopState {
  const ShopState();
}

/// 営業している（閉店・一時閉店の予定を持つこともある）。
final class ShopOpen extends ShopState {
  const ShopOpen({
    this.closingAt,
    this.reopensAt,
    this.tempClosedFrom,
    this.tempClosedUntil,
  });

  /// これから閉店する時刻。
  final DateTime? closingAt;

  /// [closingAt] の後に再開する時刻（改装の予定）。**無ければ閉店の予定。**
  final DateTime? reopensAt;

  /// これから一時閉店する期間（カレンダーの「一時閉店」）。**日付だけ**。
  final String? tempClosedFrom;
  final String? tempClosedUntil;
}

/// 一時閉店している（改装など）。[reopensAt] / [until] が無ければ再開日未定。
final class ShopTemporarilyClosed extends ShopState {
  const ShopTemporarilyClosed({this.reopensAt, this.until});

  /// 再開の時刻（`opening_date` から分かる時）。
  final DateTime? reopensAt;

  /// 再開日（`temp_closed.end_date`。日付だけ）。
  final String? until;
}

/// まだ開店していない（新店）。
final class ShopNotYetOpen extends ShopState {
  const ShopNotYetOpen(this.opensAt);

  final DateTime opensAt;
}

/// 閉店した。
final class ShopClosed extends ShopState {
  const ShopClosed();
}

extension ShopStateX on ShopState {
  /// いま店に入れるか。**入れない店の印は薄く描く。**
  bool get isOpen => this is ShopOpen;
}

/// 閉店日・開店日を時系列の出来事とみなし、いまの状態を求める。
///
/// **牛めしレーダーの `Shop.isOpen`（`gyumeshi-rader-app` の
/// `lib/data/models/shop.dart`）の判定を写したもの。** 以下の注記も写してある:
///
/// > 2 つの日付の前後関係で意味が変わるので、順序を仮定しないこと。
/// > closing→opening は改装での一時閉店だが、opening→closing は
/// > 「開店してから閉店する」新店の予定であり、区間の内外が逆になる。
///
/// **レーダーから変えたところ:**
///
/// - 時刻は JST として読む（[parseJst]。レーダーは端末のタイムゾーンで読む）
/// - **`temp_closed` を先に見る。** カレンダーの「一時閉店」と同じ答えで、
///   `closing_date` / `opening_date` を持たない店にも入る（本番で板橋区役所前店）。
///   日付だけなので、その日の 0:00（JST）から再開日の 0:00 までを閉店中とみなす
///   （再開日の朝から開く。カレンダーと同じ読み方）
ShopState shopStateOf(Shop shop, {DateTime? now}) {
  final at = now ?? clock.now();

  final temp = shop.tempClosed;
  if (temp != null) {
    final from = parseJst(temp.startDate);
    final until = parseJst(temp.endDate);
    if (from != null &&
        !at.isBefore(from) &&
        (until == null || at.isBefore(until))) {
      return ShopTemporarilyClosed(until: temp.endDate);
    }
  }

  final closing = parseJst(shop.closingDate);
  final opening = parseJst(shop.openingDate);

  // これからの一時閉店（期間がまだ来ていないもの）は、営業中の店に添えて出す
  final upcomingTemp =
      temp != null && (parseJst(temp.startDate)?.isAfter(at) ?? false)
      ? temp
      : null;

  final closingAhead = closing != null && closing.isAfter(at) ? closing : null;
  ShopState open() => ShopOpen(
    closingAt: closingAhead,
    // 閉店の後に開店が控えていれば改装（閉店 → 開店）。閉店の予定と取り違えない
    reopensAt:
        closingAhead != null && opening != null && opening.isAfter(closingAhead)
        ? opening
        : null,
    tempClosedFrom: upcomingTemp?.startDate,
    tempClosedUntil: upcomingTemp?.endDate,
  );

  if (closing == null && opening == null) return open();

  final closed = closing != null && !at.isBefore(closing);
  final opened = opening != null && !at.isBefore(opening);

  // 過ぎた日付があれば、最後に過ぎたほうが現在の状態を決める
  if (closed || opened) {
    if (closed && opened) {
      return opening.isAfter(closing) ? open() : const ShopClosed();
    }
    if (opened) return open();
    // 閉店を過ぎた。**再開が控えていれば一時閉店**（改装）
    return opening != null
        ? ShopTemporarilyClosed(reopensAt: opening)
        : const ShopClosed();
  }

  // どちらも未到来。先に来るほうの種類で現在の状態が決まる
  // （閉店が先＝今はまだ営業中／開店が先＝まだ開店していない）
  if (closing != null && opening != null) {
    return closing.isBefore(opening) ? open() : ShopNotYetOpen(opening);
  }
  return closing != null ? open() : ShopNotYetOpen(opening!);
}
