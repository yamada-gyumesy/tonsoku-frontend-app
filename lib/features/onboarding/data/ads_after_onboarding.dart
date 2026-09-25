import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/features/onboarding/data/onboarding_store.dart';

/// 広告の SDK（同意（UMP）→ ATT → 初期化）を、**オンボーディングが終わってから**
/// 始める。**呼ぶのは `main.dart` の 1 か所だけ**（最初のフレームの後）。
///
/// - **初回起動**: オンボーディングを閉じるまで待つ。そのまま始めると、
///   オンボーディングの上に同意と ATT が被さり、2 枚目の通知の許可とも重なる
///   （[waitForOnboarding] の doc）
/// - **2 回目以降**: 待たずにすぐ始める（オンボーディングを出さないため）
///
/// 出す枠が 1 つも無い時（本番の ID が空・広告を外す課金）は、
/// [AdsController.start] が SDK にも ATT にも触れない。
Future<void> startAdsAfterOnboarding(ProviderContainer container) async {
  await waitForOnboarding(container);
  await container.read(adsControllerProvider.notifier).start();
}
