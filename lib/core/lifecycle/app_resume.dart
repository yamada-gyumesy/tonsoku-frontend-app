import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// アプリがバックグラウンドから戻ってきたことを知らせる。
///
/// state は「戻ってきた回数」。値そのものに意味は無く、**変化したこと**を
/// 画面が拾う。
class AppResumeSignal extends Notifier<int> {
  @override
  int build() {
    final observer = _ResumeObserver(() => state = state + 1);
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
    return 0;
  }
}

final appResumeSignalProvider = NotifierProvider<AppResumeSignal, int>(
  AppResumeSignal.new,
);

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // **`resumed` だけを拾う。** `inactive` は通知センターを引き下げた・
    // 電話がかかってきた等でも来るので、そこで取り直すと通信が無駄に増える
    if (state == AppLifecycleState.resumed) onResume();
  }
}

/// アプリがアクティブになるたびに [onResume] を呼ぶ。
///
/// `ConsumerWidget` / `ConsumerState` の `build` 内で呼ぶこと。
void listenAppResume(WidgetRef ref, VoidCallback onResume) {
  ref.listen(appResumeSignalProvider, (_, _) => onResume());
}
