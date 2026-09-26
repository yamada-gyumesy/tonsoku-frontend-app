import 'dart:async';

import 'package:tonsoku/core/purchase/purchase_gateway.dart';

/// テスト用のストア。**本物のストアに触れない。**
///
/// [buyResult] を設定しておくと、購入を始めた直後にその知らせを流す（ストアの
/// シートで何かが起きたことにする）。null なら何も流さない（シートが開いたまま）。
class FakePurchaseGateway implements PurchaseGateway {
  FakePurchaseGateway({
    this.ownership = Ownership.notOwned,
    this.price = '¥550',
    this.buyStart = BuyStart.started,
    this.buyResult = PurchaseUpdate.purchased,
  });

  Ownership ownership;

  /// 取れる表示価格。null なら商品が取れない。
  String? price;
  BuyStart buyStart;
  PurchaseUpdate? buyResult;

  final calls = <String>[];
  final _updates = StreamController<PurchaseUpdate>.broadcast();

  /// ストアから知らせが届いた（アプリの外で済んだ購入など）。
  void emit(PurchaseUpdate update) => _updates.add(update);

  @override
  Stream<PurchaseUpdate> get updates => _updates.stream;

  @override
  Future<StoreProduct?> loadProduct() async {
    calls.add('loadProduct');
    final price = this.price;
    return price == null
        ? null
        : StoreProduct(id: removeAdsProductId, price: price);
  }

  @override
  Future<BuyStart> buy() async {
    calls.add('buy');
    final result = buyResult;
    if (buyStart == BuyStart.started && result != null) {
      scheduleMicrotask(() => _updates.add(result));
    }
    return buyStart;
  }

  @override
  Future<Ownership> queryOwnership() async {
    calls.add('queryOwnership');
    return ownership;
  }
}
