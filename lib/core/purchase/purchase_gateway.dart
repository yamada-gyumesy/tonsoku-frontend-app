import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// 広告を外す（買い切り・非消耗型）の商品 ID。**iOS / Android で共通。**
///
/// **定義の出どころは `iap_products.yaml` の 1 か所だけ**（ストアへの登録は
/// そのファイルを読む `register_iap` の lane が行う）。ここはアプリが読む写しで、
/// **食い違うと商品が 1 件も取れず、誰も買えない**（型もビルドも通る）。
/// `test/core/purchase/iap_products_test.dart` が突き合わせている。
///
/// **登録した後は変えられない・使い回せない**（両ストアとも。消しても同じ ID は
/// 二度と使えない）。
const removeAdsProductId = 'tonsoku.non_consumable.remove_ads';

/// ストアから取った商品。**価格はストアが返した表示用の文字列をそのまま出す**
/// （アプリで金額を持たない。ストアの実価格と必ず一致させるため。three と同じ）。
@immutable
class StoreProduct {
  const StoreProduct({required this.id, required this.price});

  final String id;

  /// 通貨記号付きの表示価格（例: `¥550`）。
  final String price;
}

/// 購入の知らせ（ストアから非同期に届く）。
enum PurchaseUpdate {
  /// 保留（Android のコンビニ払いなど、支払いが済むまで待つもの。iOS の
  /// 「承認と購入のリクエスト」も同じ）。**まだ広告は外さない。**
  pending,

  /// 買えた。
  purchased,

  /// 復元できた（ストアの購入記録から）。
  restored,

  /// ストアのシートで閉じた。
  canceled,

  /// 買えなかった。
  failed,
}

/// ストアの購入記録を見た結果。
enum Ownership {
  /// 持っている（支払い済み）。
  owned,

  /// 保留中の購入がある（支払いを待っている）。
  pending,

  /// ストアははっきり「持っていない」と答えた。
  notOwned,

  /// ストアに問い合わせられなかった（圏外・ストアのアプリが無い・エラー）。
  /// **持っているかどうか分からない。**
  unknown,
}

/// 購入を始めた結果。**結果そのものは [PurchaseGateway.updates] に届く。**
enum BuyStart {
  /// ストアのシートを出した。
  started,

  /// ストアに繋がらない・商品が取れない。
  unavailable,

  /// ストアが受け付けなかった（未完了の取引が残っている等）。
  failed,
}

/// アプリ内課金のストア（App Store / Google Play）との境目。**画面と状態は
/// ここだけを通してストアに触る** ―― テストで本物のストアに触れないため
/// （`adGatewayProvider` と同じ流儀。テストは偽物に差し替える）。
///
/// **扱うのは [removeAdsProductId] の 1 つだけ。** in_app_purchase の型はここに
/// 閉じ込め、外には [PurchaseUpdate] / [Ownership] だけを出す（three の
/// `SubscriptionPurchaseRepository` と同じ分け方）。
abstract class PurchaseGateway {
  /// 購入の知らせ。**ストアへの完了の知らせ（iOS の finish・Android の
  /// acknowledge）は済ませてから流す。**
  Stream<PurchaseUpdate> get updates;

  /// 商品（表示価格）。取れなければ null。
  Future<StoreProduct?> loadProduct();

  /// 購入を始める。
  Future<BuyStart> buy();

  /// ストアの購入記録を見る（復元と、起動時の突き合わせ）。
  Future<Ownership> queryOwnership();
}

final purchaseGatewayProvider = Provider<PurchaseGateway>((ref) {
  final gateway = InAppPurchaseGateway();
  ref.onDispose(gateway.dispose);
  return gateway;
});

/// `in_app_purchase`（StoreKit 2 / Google Play Billing）での実装。
///
/// ## three-frontend-flutter から写したもの・写さなかったもの
///
/// 写したのは `IapSubscriptionPurchaseRepository` の骨組み（`purchaseStream` を
/// 購読して結果に直し、完了の知らせ（`completePurchase`）まで済ませる・
/// `buyNonConsumable` が false の時に失敗を流す・商品の取得をキャッシュする）。
///
/// 写さなかったもの:
///
/// - **サーバーでの確定（confirm API）と、その一時失敗で finalize を遅らせる
///   仕組み。** とん速はサーバーを持たない（買い切りなので、端末とストアの記録で
///   足りる。Issue #42）。**届いたらすぐ端末に残してから完了を知らせる**
/// - **購入とユーザーの紐付け（appAccountToken / obfuscatedAccountId）。**
///   ログインが無く、紐付ける相手がいない
/// - **通貨の検証（`hasTrustworthyPrice`）。** three は販売地域が日本だけなので
///   JPY 以外を「ストアの不整合」として捨てているが、**とん速は英語・中国語の
///   画面を持ち、販売地域を日本に絞る前提が無い**。JPY 以外も正しい値でありうる
///   ので、ストアの値をそのまま出す（TestFlight / サンドボックスで USD が出るのは
///   three の実測どおり Apple 側の既知の挙動で、本番では出ない）
/// - **取りこぼしの回収（`takePendingOutcome`）。** 購読は起動時に始めて
///   アプリが生きている間ずっと続ける（`RemoveAdsController.start`）ので、
///   聞き手の居ない時間が無い
///
/// ## 復元は OS ごとに問い合わせ方を変える
///
/// - **Android は `queryPastPurchases` で直接聞く**（`restorePurchases` を使わない）。
///   `restorePurchases` は**保留中（pending）の購入まで `restored` に書き換えて
///   流す**（`in_app_purchase_android` 0.5.3 の
///   `InAppPurchaseAndroidPlatform.restorePurchases`）ので、払っていない人の
///   広告が消える。`queryPastPurchases` は購入の状態をそのまま返し、失敗も
///   返り値で分かる
/// - **iOS は `restorePurchases`**（StoreKit 2 の `Transaction.currentEntitlements`。
///   **返金・取り消しされた購入は入らない**。Apple ID のパスワードは求めない）。
///   結果は `purchaseStream` に**1 回のまとまり**で届く（持っていなければ空の
///   まとまり。`in_app_purchase_storekit` 0.4.11+1 以降）ので、それを待つ。
///   それより前の版は持っていない時に何も流さず、[_restoreTimeout] の後に
///   「分からない」になる（広告を戻さない側に倒れる）
///
/// **iOS の `Transaction.updates` は取り消しも `purchased` として流す**
/// （プラグインが取り消しの日付を渡さない）。アプリを開いている間に返金された
/// 時は一度「買えた」扱いになるが、次の起動の突き合わせで戻る
/// （`RemoveAdsController` の「返金・取り消しの扱い」）
class InAppPurchaseGateway implements PurchaseGateway {
  /// iOS の復元の結果（`purchaseStream` のまとまり）を待つ上限。**過ぎたら
  /// 「分からない」にする**（「持っていない」にはしない。起動時の突き合わせで
  /// 広告を戻してしまうため）。
  static const _restoreTimeout = Duration(seconds: 15);

  /// **最初に使う時まで `InAppPurchase.instance` に触らない**（テストや、
  /// 課金に触れずに終わる起動でプラグインを立ち上げない）。
  InAppPurchase get _iap => InAppPurchase.instance;

  StreamController<PurchaseUpdate>? _updates;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? _product;

  /// iOS の復元の結果を待っている間だけ持つ。
  Completer<bool>? _restoreBatch;

  @override
  Stream<PurchaseUpdate> get updates {
    _listen();
    return _updates!.stream;
  }

  void _listen() {
    if (_updates != null) return;
    _updates = StreamController<PurchaseUpdate>.broadcast();
    _sub = _iap.purchaseStream.listen(
      (purchases) => unawaited(_onPurchases(purchases)),
      onError: (Object error) {
        debugPrint('purchaseStream のエラー: $error');
        _updates?.add(PurchaseUpdate.failed);
      },
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    // **iOS の復元の結果は 1 回のまとまりで届く**（空でも届く）。復元を待って
    // いる間に、全部が `restored` のまとまり（空を含む）が来たらそれが答え
    final waiting = _restoreBatch;
    if (waiting != null &&
        !waiting.isCompleted &&
        purchases.every((p) => p.status == PurchaseStatus.restored)) {
      waiting.complete(purchases.any((p) => p.productID == removeAdsProductId));
    }

    for (final purchase in purchases) {
      final ours = purchase.productID == removeAdsProductId;
      final update = switch (purchase.status) {
        PurchaseStatus.pending => PurchaseUpdate.pending,
        PurchaseStatus.purchased => PurchaseUpdate.purchased,
        PurchaseStatus.restored => PurchaseUpdate.restored,
        PurchaseStatus.canceled => PurchaseUpdate.canceled,
        PurchaseStatus.error => PurchaseUpdate.failed,
      };
      if (update == PurchaseUpdate.failed) {
        debugPrint(
          '購入のエラー: ${purchase.error?.code} ${purchase.error?.message}',
        );
      }
      // **先に知らせてから完了を知らせる。** 知らせを受けた側が端末に残す
      // （`RemoveAdsController`）。完了を先にすると、残す前に落ちた時に
      // ストアが送り直さない（Android は 3 日以内に acknowledge しないと
      // 自動で返金される）。**保留中は完了を知らせない**（支払いが済んでいない）
      if (ours) _updates?.add(update);
      if (update != PurchaseUpdate.pending) await _complete(purchase);
    }
  }

  Future<void> _complete(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(purchase);
    } on Object catch (error) {
      // 完了を知らせられなくても、端末には残してある。**未完了のまま残った取引は
      // ストアが次の起動で送り直す**ので、そこでもう一度知らせる（three と同じ）
      debugPrint('completePurchase に失敗しました: $error');
    }
  }

  Future<ProductDetails?> _queryProduct() async {
    final cached = _product;
    if (cached != null) return cached;
    try {
      if (!await _iap.isAvailable()) return null;
      final response = await _iap.queryProductDetails({removeAdsProductId});
      if (response.error != null) {
        debugPrint('queryProductDetails に失敗しました: ${response.error!.message}');
      }
      if (response.productDetails.isEmpty) return null;
      return _product = response.productDetails.first;
    } on Object catch (error) {
      debugPrint('商品を取得できませんでした: $error');
      return null;
    }
  }

  @override
  Future<StoreProduct?> loadProduct() async {
    final product = await _queryProduct();
    return product == null
        ? null
        : StoreProduct(id: product.id, price: product.price);
  }

  @override
  Future<BuyStart> buy() async {
    _listen();
    final product = await _queryProduct();
    if (product == null) return BuyStart.unavailable;
    try {
      // **false はストアに送られなかった**（未完了の取引が残っている等）。
      // この時は `purchaseStream` に何も来ないので、ここで失敗にしないと
      // 読み込み中のまま固まる（three の注記）
      final requested = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      return requested ? BuyStart.started : BuyStart.failed;
    } on Object catch (error) {
      debugPrint('購入を始められませんでした: $error');
      return BuyStart.failed;
    }
  }

  @override
  Future<Ownership> queryOwnership() async {
    _listen();
    try {
      if (!await _iap.isAvailable()) return Ownership.unknown;
      return defaultTargetPlatform == TargetPlatform.android
          ? await _queryAndroid()
          : await _queryIos();
    } on Object catch (error) {
      debugPrint('購入記録を確かめられませんでした: $error');
      return Ownership.unknown;
    }
  }

  Future<Ownership> _queryAndroid() async {
    final addition = _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      debugPrint('queryPastPurchases に失敗しました: ${response.error!.message}');
      return Ownership.unknown;
    }
    // **Play は返金・取り消しされた購入を返さない**（持っているものだけ）
    final ours = response.pastPurchases
        .where((p) => p.productID == removeAdsProductId)
        .toList();
    final paid = ours.where((p) => p.status == PurchaseStatus.purchased);
    if (paid.isNotEmpty) {
      // **acknowledge していない購入はここで知らせる**（3 日以内に知らせないと
      // Play が自動で返金する）。アプリが落ちて `purchaseStream` で完了を
      // 知らせ損ねた購入が、ここで拾われる
      for (final purchase in paid) {
        await _complete(purchase);
      }
      return Ownership.owned;
    }
    if (ours.any((p) => p.status == PurchaseStatus.pending)) {
      return Ownership.pending;
    }
    return Ownership.notOwned;
  }

  /// 走っている iOS の問い合わせ。**重ねて聞かない**（起動時の突き合わせの最中に
  /// 「購入を復元」を押された時など）。結果のまとまりはどちらの問い合わせの
  /// ものか見分けられないので、同じ答えを返す。
  Future<Ownership>? _iosQuery;

  Future<Ownership> _queryIos() =>
      _iosQuery ??= _runIosQuery().whenComplete(() => _iosQuery = null);

  Future<Ownership> _runIosQuery() async {
    final batch = _restoreBatch = Completer<bool>();
    try {
      await _iap.restorePurchases();
      final owned = await batch.future.timeout(_restoreTimeout);
      return owned ? Ownership.owned : Ownership.notOwned;
    } on TimeoutException {
      return Ownership.unknown;
    } finally {
      _restoreBatch = null;
    }
  }

  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_updates?.close());
  }
}
