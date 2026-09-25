import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/app.dart';
import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/licenses/font_licenses.dart';
import 'package:tonsoku/core/licenses/map_data_license.dart';
import 'package:tonsoku/core/storage/json_cache.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';
import 'package:tonsoku/features/notifications/data/push_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 同梱書体（Klee One / Noto Sans JP）のライセンスをライセンス表記に載せる
  registerFontLicenses();
  registerMapDataLicense();

  // 保存済みのテーマ・言語を反映してから最初のフレームを描く。非同期のまま
  // 起動すると、既定値で一瞬描いてから設定値に差し替わってちらつく
  final prefs = await SharedPreferences.getInstance();
  final cache = await JsonCache.open();

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
    await registerPushHandlers();
  } catch (error, stack) {
    debugPrint('Firebase の初期化に失敗しました: $error\n$stack');
  }

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      jsonCacheProvider.overrideWithValue(cache),
    ],
  );
  runApp(
    UncontrolledProviderScope(container: container, child: const TonsokuApp()),
  );

  // **広告の SDK は最初のフレームの後に始める**（同意（UMP）→ ATT → 初期化。
  // `AdsController`）。ATT のダイアログは画面が出る前に求めると出ないことがある。
  // **ATT を聞く場所はオンボーディング（#7）で決め直す** ―― 決まったら、この
  // 呼び出しをそこへ移す（呼び出しはここ 1 か所だけ）。出す枠が 1 つも無い時
  // （本番の ID が空・広告を外す課金）は SDK にも ATT にも触れない
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => unawaited(container.read(adsControllerProvider.notifier).start()),
  );
}
