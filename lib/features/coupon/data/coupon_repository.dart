import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/cdn/cdn_paths.dart';
import 'package:tonsoku/core/cdn/cdn_repository.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/network/cdn_client.dart';
import 'package:tonsoku/shared/models/coupon.dart';

/// `coupon.json` の取得。
///
/// **404 を正常系として扱ってよい数少ない配信物**（`CdnPaths` 参照）。
/// 配信が始まっていないロケールでは 404 が返りうるので、**「取れなかった」と
/// 「まだ無い」を分けて**扱う。取得失敗（通信断・壊れた JSON）は今までどおり
/// 例外として流す —— **そこを空に潰すと、通信エラーが「クーポンが無い」に化ける。**
class CouponRepository {
  CouponRepository({required this._cdn, required AppLocale locale})
    : _paths = CdnPaths(locale);

  final CdnRepository _cdn;
  final CdnPaths _paths;

  /// 配信を流す。**まだ配信されていない（404）時は null。**
  ///
  /// **`yield*` を使わないこと。** 委譲は**エラーをその場で throw せず出力
  /// ストリームへ直に転送する**ので、囲んだ `try` / `on CdnNotFoundException` を
  /// 素通りする（実測: `yield*` は例外のまま抜け、`await for` は `[null]` を流す）。
  /// そうなると 404 のロケールで画面が `LoadFailure` を出し、**押しても永久に
  /// 成功しない再試行**が並ぶ。
  Stream<Coupon?> watch() async* {
    try {
      await for (final coupon in _cdn.watch(_paths.coupon, _decode)) {
        yield coupon;
      }
    } on CdnNotFoundException {
      yield null;
    }
  }

  /// 取り直す（引っ張って更新）。
  ///
  /// **まだ配信されていない時は黙って諦める。** 404 は「無い」であって失敗では
  /// ないので、更新の輪だけ回して何も起きないのが正しい。
  Future<void> refreshCoupon() async {
    try {
      await _cdn.fetchFresh(_paths.coupon, _decode);
    } on CdnNotFoundException {
      // 無いものは無い
    }
  }

  /// 取り直して、**本文が変わった時だけ true**（ホームのアクティブ復帰用。
  /// `CdnRepository.fetchFreshIfChanged`）。**まだ配信されていなければ false。**
  Future<bool> refreshCouponIfChanged() async {
    try {
      return await _cdn.fetchFreshIfChanged(_paths.coupon, _decode);
    } on CdnNotFoundException {
      return false;
    }
  }

  static Coupon _decode(String body) =>
      Coupon.fromJson(jsonDecode(body) as Map<String, dynamic>);
}

final couponRepositoryProvider = Provider<CouponRepository>(
  (ref) => CouponRepository(
    cdn: ref.watch(cdnRepositoryProvider),
    locale: ref.watch(localeControllerProvider),
  ),
);

/// クーポン配信。**null は「まだ配信されていない」**で、取得失敗ではない。
final couponProvider = StreamProvider<Coupon?>(
  (ref) => ref.watch(couponRepositoryProvider).watch(),
);
