import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/app.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/licenses/font_licenses.dart';
import 'package:tonsoku/core/licenses/map_data_license.dart';
import 'package:tonsoku/core/storage/json_cache.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/features/notifications/data/push_bootstrap.dart';
import 'package:tonsoku/features/onboarding/data/ads_after_onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 同梱書体（Klee One / Noto Sans JP）のライセンスをライセンス表記に載せる
  registerFontLicenses();
  registerMapDataLicense();

  // 保存済みのテーマ・言語を反映してから最初のフレームを描く。非同期のまま
  // 起動すると、既定値で一瞬描いてから設定値に差し替わってちらつく
  final prefs = await SharedPreferences.getInstance();
  final cache = await JsonCache.open();

  // **コンテナを Firebase より先に作る。** 通知チャンネルの名前に、保存済みの
  // 表示言語が要る（`registerPushHandlers`）
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      jsonCacheProvider.overrideWithValue(cache),
    ],
  );

  // **設定ファイルは `options:` で渡さない**（gyumesy と同じ）。Android は
  // `google-services.json`、iOS は `GoogleService-Info.plist` をネイティブ側が
  // 読む。Dart 側に写しを置くと、Terraform が出す値と二重管理になる
  //
  // **通知を使う画面が無くても初期化する。** 通知のタップで起動した時、
  // 画面が立ち上がるより前に受け取りの用意が要る
  // **失敗してもアプリは起動させる。** 設定ファイルが欠けている・古い等で
  // ここが投げると、記事を読むだけの人まで真っ白な画面を見ることになる。
  // 通知が使えないことは通知設定の画面で分かる
  try {
    await Firebase.initializeApp();
    await registerPushHandlers(container.read(localeControllerProvider));
  } catch (error, stack) {
    debugPrint('Firebase の初期化に失敗しました: $error\n$stack');
  }
  // **表示言語を切り替えたら、通知チャンネルの名前も付け直す**（端末の通知設定に
  // 出る名前。[syncNotificationChannel]）。初期化に失敗した時は何もしない
  container.listen(
    localeControllerProvider,
    (_, locale) => unawaited(syncNotificationChannel(locale)),
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const TonsokuApp()),
  );

  // **広告の SDK は最初のフレームの後、オンボーディングが終わってから始める**
  // （同意（UMP）→ ATT → 初期化）。ATT のダイアログは画面が出る前に求めると
  // 出ないことがある。初回起動はオンボーディングを閉じるまで待ち、2 回目以降は
  // すぐ始まる（理由は [startAdsAfterOnboarding]）。**呼び出しはここ 1 か所だけ**
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => unawaited(startAdsAfterOnboarding(container)),
  );
}
