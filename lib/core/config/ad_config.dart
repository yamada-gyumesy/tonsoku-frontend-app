import 'package:flutter/foundation.dart';

/// 広告の枠。**枠ごとに別の広告ユニットを割る**（web の `adsenseSlots` と同じ）。
///
/// 1 つを使い回すと、どの位置が稼いでいるのかが AdMob の管理画面で分けて
/// 見られない ―― **位置を動かす判断ができなくなる**（web の `config.ts`）。
enum AdSlot {
  /// 下タブの上に固定するアンカーのアダプティブバナー（全タブ）。
  anchorBanner,

  /// 記事詳細の本文の後・関連記事より前（web の `articleBottom`）。**記事の枠は
  /// これ 1 つだけ**（web の 3 枠は写さない。ユーザーの判断）。
  articleInline,

  /// マップのリワード動画（見ると店舗限定の表示を 6 時間開放する）。
  mapRewarded,
}

/// 広告の設定。web（`tonsoku-frontend-web`）の `src/config.ts` の
/// `adsenseClientId` / `adsenseSlots` に相当する。
///
/// ---- 本番の ID が空の枠は何も出さない ----
///
/// **本番の広告ユニット ID が空の枠は、枠も初期化も一切しない**（web の
/// 「ID が空の間は広告に関わる出力が 1 つも出ない」と同じ）。**全部の枠が空なら
/// SDK の初期化も、同意（UMP）も、ATT の確認も出さない**（[enabled]）。
/// いまは AdMob のアプリとユニットを作る前なので、本番はすべて空。
///
/// ---- 手元・テストでは本番の広告を出さない ----
///
/// **release 以外（debug / profile / テスト）は Google 公式のテスト用 ID を使う。**
/// 手元で本番の広告を表示させると無効なインプレッションになる（web の
/// `adsenseClientId` と同じ扱い）。テスト用 ID の広告は数えられないので、
/// 枠の位置や高さの確認に使ってよい。**テストはさらに広告の読み込み自体を
/// 差し替える**（`adGatewayProvider`）。
///
/// ---- アプリ内課金で広告を外す時 ----
///
/// [adsRemoved] が真なら全部の枠が空扱いになり、**SDK の初期化も ATT の確認も
/// 起きない**。広告を外す課金（将来）を入れる時は、購入済みの端末でここを真に
/// する ―― **購入済みの人に SDK を初期化させない・ATT を聞かない**こと
/// （追跡しない人に追跡の許可を求めるのは筋が通らない）。
@immutable
class AdConfig {
  const AdConfig({required this.units, this.adsRemoved = false});

  /// 枠ごとの広告ユニット ID。空文字・欠けは「その枠は出さない」。
  final Map<AdSlot, String> units;

  /// 広告を外す（将来の課金）。真なら全部の枠が出ない。
  final bool adsRemoved;

  /// [slot] の広告ユニット ID。**出さない枠は null。**
  String? unitId(AdSlot slot) {
    if (adsRemoved) return null;
    final id = units[slot];
    return (id == null || id.isEmpty) ? null : id;
  }

  /// 1 つでも出す枠があるか。**偽なら SDK に一切触れない**（初期化・UMP・ATT）。
  bool get enabled => AdSlot.values.any((s) => unitId(s) != null);

  // ---- 本番の広告ユニット ID（リリース前に埋める）----
  //
  // **AdMob ではアプリが OS ごとに別**なので、ユニットも OS ごとに 3 つずつ作る。
  // **アプリ ID（`ca-app-pub-…~…`）は別の場所**: iOS は `ios/Runner/Info.plist` の
  // `GADApplicationIdentifier`、Android は `android/app/src/main/AndroidManifest.xml`
  // の `com.google.android.gms.ads.APPLICATION_ID`（どちらも今はテスト用の値）。
  //
  // **これは秘密ではない**（アプリに埋め込んで配る前提の識別子。web の
  // `adsenseClientId` と同じ扱い）。

  static const productionIos = <AdSlot, String>{
    AdSlot.anchorBanner: '',
    AdSlot.articleInline: '',
    AdSlot.mapRewarded: '',
  };

  static const productionAndroid = <AdSlot, String>{
    AdSlot.anchorBanner: '',
    AdSlot.articleInline: '',
    AdSlot.mapRewarded: '',
  };

  // ---- Google 公式のテスト用 ID ----
  // https://developers.google.com/admob/ios/test-ads
  // https://developers.google.com/admob/android/test-ads
  // バナーは「アダプティブバナー」用のテスト ID（固定サイズ用とは別）。

  static const testIos = <AdSlot, String>{
    AdSlot.anchorBanner: 'ca-app-pub-3940256099942544/2435281174',
    AdSlot.articleInline: 'ca-app-pub-3940256099942544/2435281174',
    AdSlot.mapRewarded: 'ca-app-pub-3940256099942544/1712485313',
  };

  static const testAndroid = <AdSlot, String>{
    AdSlot.anchorBanner: 'ca-app-pub-3940256099942544/9214589741',
    AdSlot.articleInline: 'ca-app-pub-3940256099942544/9214589741',
    AdSlot.mapRewarded: 'ca-app-pub-3940256099942544/5224354917',
  };

  /// ビルドの種類と OS から決める。**release だけが本番の ID を使う。**
  factory AdConfig.resolve({bool? release, TargetPlatform? platform}) {
    final isRelease = release ?? kReleaseMode;
    final isIos = (platform ?? defaultTargetPlatform) == TargetPlatform.iOS;
    return AdConfig(
      units: isRelease
          ? (isIos ? productionIos : productionAndroid)
          : (isIos ? testIos : testAndroid),
    );
  }
}
