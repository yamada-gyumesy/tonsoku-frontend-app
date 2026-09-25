import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/analytics/screen_path.dart';

/// GA4 へ画面を送る所を 1 箇所に閉じる。gyumesy-frontend-app の同名のものを
/// 写した（下の「なぜ `page_view` を送らないか」など、gyumesy の実測の経緯も
/// そのまま残してある）。
///
/// **画面から `FirebaseAnalytics` を直接呼ばない**（テストで差し替えられなく
/// なるうえ、パスの組み立てが散る）。
abstract class Analytics {
  /// 画面を見たことを送る。
  ///
  /// **`screen_view` を送る**（`logScreenView`）。アプリのイベントは
  /// `screen_view`、web は `page_view` ——**プラットフォームごとに素の形で
  /// 送り、統合はレポート側で行う**のが GA4 の設計。
  ///
  /// ## web と同じ行に並ぶ仕組み
  ///
  /// 統合ディメンションは**次の対で組まれている**。
  ///
  /// | 列 | web | アプリ |
  /// |---|---|---|
  /// | ページタイトルとスクリーン名 | ページタイトル | **スクリーン名** |
  /// | ページパスとスクリーン クラス | ページパス | **スクリーン クラス** |
  ///
  /// **`screenName` に web の `<title>` を入れる**のはこのため。
  /// `ScreenPath.title` は web の `<title>` と 1 文字違わないよう組んで
  /// あるので、同じ画面の app と web が 1 行に並ぶ（Issue #7 の狙い）。
  ///
  /// **`screenClass` には web の URL を入れる**（`ScreenPath.screenClass`）。
  /// パスの列でも並ぶので、**2 列とも web と揃う。**
  ///
  /// **どちらの列にも「画面の種類」のような独自の名前を入れないこと。**
  /// gyumesy は以前 `screenClass` に `Home` / `Article` を入れていたが、web 側は URL を
  /// 出すので**パスの列で絶対に並ばず、パスでの集計を潰していた**。
  /// 束ねたい時はスクリーン名の前方一致か BigQuery で行う。
  ///
  /// **`screenName` に URL を入れるのも駄目。** 題の列に URL が並び、
  /// ホームは `/` という読めない行になる（実際にそう出た）。
  ///
  /// ## 題が長いと題の列だけ割れる
  ///
  /// **上限がパラメータごとに違う。** `firebase_screen`（スクリーン名）は
  /// **100 文字**、web の `page_title` は **300 文字**。web は切らずに送るので
  /// （`BaseLayout.astro` の `<title>{title}</title>`）、**100 文字を超える題は
  /// アプリ側だけ切られて別の値になり、題の列で 2 行に割れる。**
  ///
  /// とん速の実測（2026-09-26 の配信 36 件。接尾辞 ` | とん速` 等を含めた長さ）:
  /// 日本語・簡体字は最大 38 文字＋接尾辞で問題ないが、**英語は 13 件が
  /// 100 文字超**（題だけで最大 105 文字）。**日本語だけ見ていると気付けない**
  /// （gyumesy でも英語だけが超えていた）。
  ///
  /// **アプリ側で切っても解決しない**（web は 300 文字まで送るので、切り方を
  /// 合わせようがない）。**長い題はパスの列で突き合わせる** ——
  /// `screenClass` に URL を入れてあるので、そちらは長さに関係なく必ず並ぶ。
  ///
  /// 「表示回数」は `page_view` と `screen_view` の合算として定義されている
  /// ので、イベント名が違っても素直に足される。
  ///
  /// ## なぜ `page_view` を送らないか
  ///
  /// **gyumesy は以前アプリからも `page_view` を送っていた。** イベント名を揃えれば
  /// 並ぶだろう、という考えだったが、**アプリ側の「スクリーン名 / スクリーン
  /// クラス」が全部 (未設定) になった。** 統合ディメンションはストリームの
  /// 種別で引く先を決めるので、アプリのイベントに `page_title` を積んでも
  /// 読まれない。
  ///
  /// **`logEvent` に `firebase_screen*` を手で載せる道は塞がれている。**
  /// `firebase_` は予約接頭辞で、ネイティブ SDK が送信前に捨てる（実測:
  /// `Parameter name uses reserved prefix. Ignoring parameter:
  /// firebase_screen_class`）。**`logScreenView` は SDK が正規に設定する経路**
  /// なので、そちらだけが通る。
  ///
  /// **両方送るのも駄目。** 表示回数が合算される以上、アプリだけ 2 倍になる。
  Future<void> screen(ScreenPath screen);
}

class FirebaseAnalyticsClient implements Analytics {
  const FirebaseAnalyticsClient(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> screen(ScreenPath screen) => _analytics.logScreenView(
    // **スクリーン名には web の `<title>` を入れる。** 統合ディメンションは
    // 「ページタイトル ↔ スクリーン名」で対になるので、ここを web の題と
    // 揃えることで同じ画面が 1 行に並ぶ（`ScreenPath.title` の doc）
    screenName: screen.screenName,
    screenClass: screen.screenClass,
  );
}

/// 何もしない実装。**Firebase の初期化に失敗した時に使う。**
/// 計測が落ちてもアプリは動くべきなので、例外を上へ流さない。
class NoopAnalytics implements Analytics {
  const NoopAnalytics();

  @override
  Future<void> screen(ScreenPath screen) async {}
}

final analyticsProvider = Provider<Analytics>((ref) {
  try {
    return FirebaseAnalyticsClient(FirebaseAnalytics.instance);
  } on Object {
    // Firebase が初期化されていない（`main` が握り潰している）
    return const NoopAnalytics();
  }
});
