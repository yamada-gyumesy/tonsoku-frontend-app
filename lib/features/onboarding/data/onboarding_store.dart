import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/core/storage/preferences_provider.dart';

/// オンボーディングを出したかどうか。gyumesy-frontend-app の同名のものを写した
/// （保存キーだけとん速のもの）。
///
/// **バージョンアップでは再表示しない。** 既存の利用者に再び出しても邪魔に
/// なるだけなので、版ではなく「一度出したか」だけを持つ。
class OnboardingStore {
  const OnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  /// **キーはとん速のもの**（通知の保存キーと同じ `tonsoku-` 始まり）。
  static const _key = 'tonsoku-onboarding-done';

  bool get isDone => _prefs.getBool(_key) ?? false;

  Future<void> markDone() => _prefs.setBool(_key, true);
}

final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => OnboardingStore(ref.watch(sharedPreferencesProvider)),
);

/// オンボーディングを見終わったか。**見終わった瞬間を外へ知らせるために持つ**
/// （gyumesy には無い。[waitForOnboarding] の doc）。
///
/// 保存そのものは [OnboardingStore] が持つ。ここは起動時にそれを読み、
/// [markDone] で `true` に変わるだけ。
class OnboardingDone extends Notifier<bool> {
  @override
  bool build() => ref.watch(onboardingStoreProvider).isDone;

  /// 見終わった。**見せたことを先に残す**（閉じる前に落ちても二度は出さない。
  /// gyumesy の `OnboardingOverlay` と同じ順）。
  void markDone() {
    unawaited(ref.read(onboardingStoreProvider).markDone());
    state = true;
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingDone, bool>(
  OnboardingDone.new,
);

/// オンボーディングが終わるまで待つ。**見終わっていればすぐ返る。**
///
/// **広告の SDK を始める合図に使う**（`startAdsAfterOnboarding`）。広告は
/// 同意（UMP）→ ATT の順にダイアログを出すので、初回起動にそのまま始めると
/// **オンボーディングの上に ATT が被さる**。2 枚目には OS の通知の許可も
/// あり、ダイアログが 2 つ重なると、どちらに答えたのか分からなくなる。
///
/// 閉じるのは「あとで」か、**通知の許可のダイアログが閉じた後**
/// （`OnboardingPage._allow` の `onPermissionDecided`）なので、ここが返った
/// 時点で通知のダイアログはもう出ていない。
///
/// **Android で 1 枚目から戻って閉じた時は返らない**（アプリごと終わる。
/// 見終わっていないので、次の起動でまたオンボーディングから始まる）。
Future<void> waitForOnboarding(ProviderContainer container) {
  if (container.read(onboardingDoneProvider)) return Future.value();
  final done = Completer<void>();
  late final ProviderSubscription<bool> sub;
  sub = container.listen<bool>(onboardingDoneProvider, (_, next) {
    if (!next || done.isCompleted) return;
    done.complete();
    sub.close();
  });
  return done.future;
}
