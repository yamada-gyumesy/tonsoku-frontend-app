import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 引っ張って更新の共通処理。
///
/// **温めてから貼り直す。** [warm] が `fetchFresh`（キャッシュを読まずに取り直す）、
/// [reattach] が `invalidate`。
///
/// - **温めるだけでは画面が変わらない。** `watch()` は最大 2 回 yield したあと
///   **完了している**ので、貼り直さないと再放出されない
/// - **貼り直すだけでは通信すらしないことがある。** `watch()` が先に流す
///   キャッシュ値で即座に解決してしまう（riverpod で実測 4ms）。
///   `refreshArticleLists` の doc が名指しで駄目と書いている形
///
/// 温めた直後なら `CdnRepository.freshWindow` が効くので、貼り直しても二重に
/// 取りに行かない（実測でパスごとの取得回数がちょうど 1 回だけ増える）。
///
/// ## `ref` ではなく [ProviderContainer] を渡す理由
///
/// **[warm] は通信なので待ち時間がある。その間に画面を閉じられる。**
/// 積んだ画面（記事詳細・通知設定）で引っ張ってすぐ「＜ 戻る」を押すと widget が
/// 外れ、そのあと `ref` を使うと
/// `Bad state: Using "ref" when a widget is about to or has been unmounted` で
/// 落ちる。**`RefreshIndicator` はこの例外も拾わない**ので、ゾーンの未処理
/// エラーになるだけで誰にも伝わらない。
///
/// **`await` の前に容れ物を捕まえておけば、外れた後でも安全に貼り直せる。**
/// 呼び出し側で `mounted` を見る形にすると、**次に足す画面で同じことが起きる**
/// ので、ここで担保する。
///
/// ## 失敗した時に何が起きるか
///
/// **例外は握り潰し、画面は前の値を出したままにする。** `RefreshIndicator` は
/// [warm] のエラーを拾わず（Flutter 本体が `whenComplete` の戻り値を捨てている）、
/// **輪は普通に閉じる**ので、投げても利用者には何も伝わらない。
///
/// **「provider が error 状態を持つから画面が出す」とは限らない。** 実測では
/// キャッシュも値もある状態で圏外にして引くと、`hasError=false` /
/// `hasValue=true` のままで失敗の表示は 0 件になる（`watch()` が
/// キャッシュを流した後の失敗を自分で握り潰すため）。error になるのは
/// **キャッシュも値も無い初回**だけ。
///
/// **これは意図した挙動。** 一度読めている画面で、取り直しに失敗したからと
/// いって中身を消してエラーに差し替えるのは損。**古い値を出したままにする。**
///
/// **[reattach] は [warm] が失敗しても必ず呼ぶ。** `try` の中に入れると、
/// 温めに失敗した時に貼り直しへ辿り着かない。
Future<void> pullToRefresh(
  BuildContext context, {
  required Future<void> Function(ProviderContainer container) warm,
  required void Function(ProviderContainer container) reattach,
}) async {
  // **`await` の前に捕まえる**（理由は上）
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await warm(container);
  } on Object {
    // 握り潰す理由は上のとおり。ここで投げても誰にも伝わらない
  }
  reattach(container);
}
