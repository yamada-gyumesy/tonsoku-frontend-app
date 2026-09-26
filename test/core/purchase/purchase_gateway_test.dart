import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:tonsoku/core/purchase/purchase_gateway.dart';

/// ストアの知らせを「この商品のもの」として拾うか（`InAppPurchaseGateway.isOurs`）。
///
/// **Android のキャンセル・失敗は商品 ID が空で届く**（in_app_purchase_android 0.5.3）。
/// 落とすと購入を待つ側が読み込み中のまま固まる。
void main() {
  PurchaseDetails details(String id, PurchaseStatus status) => PurchaseDetails(
    productID: id,
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: '',
      source: '',
    ),
    transactionDate: null,
    status: status,
  );

  test('この商品の知らせは状態に関わらず拾う', () {
    for (final status in PurchaseStatus.values) {
      expect(
        InAppPurchaseGateway.isOurs(details(removeAdsProductId, status)),
        isTrue,
        reason: '$status',
      );
    }
  });

  test('空 ID のキャンセル・失敗は拾う（Android）', () {
    expect(
      InAppPurchaseGateway.isOurs(details('', PurchaseStatus.canceled)),
      isTrue,
    );
    expect(
      InAppPurchaseGateway.isOurs(details('', PurchaseStatus.error)),
      isTrue,
    );
  });

  test('空 ID の購入済み・復元・保留は付与の根拠にしない', () {
    for (final status in [
      PurchaseStatus.purchased,
      PurchaseStatus.restored,
      PurchaseStatus.pending,
    ]) {
      expect(
        InAppPurchaseGateway.isOurs(details('', status)),
        isFalse,
        reason: '$status',
      );
    }
  });

  test('ほかの商品の知らせは拾わない', () {
    expect(
      InAppPurchaseGateway.isOurs(details('other', PurchaseStatus.error)),
      isFalse,
    );
  });
}
