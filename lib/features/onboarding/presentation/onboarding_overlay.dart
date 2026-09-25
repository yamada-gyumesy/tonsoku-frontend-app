import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/features/onboarding/data/onboarding_store.dart';
import 'package:tonsoku/features/onboarding/presentation/onboarding_page.dart';

/// 初回だけオンボーディングを本体の上に重ねる。gyumesy-frontend-app の同名の
/// ものを写した（見終わったことを [onboardingDoneProvider] で外へ知らせる所
/// だけ違う。広告の始め時に使う）。
///
/// **ルーターの画面として持たない** —— タブや戻るの対象になってしまうし、
/// ディープリンクで記事を直接開いた時に間に挟まる。
/// **重ねるだけなら、閉じた瞬間に下の画面がそのまま出る。**
class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({
    required this.child,
    this.backButtonDispatcher,
    this.canPopUnderneath,
    super.key,
  });

  final Widget? child;

  /// ルーターの戻るの受け口。[OnboardingPage] へ渡す（戻るを先に取るため）。
  final BackButtonDispatcher? backButtonDispatcher;

  /// 下の本体で戻れる画面があるか（`GoRouter.canPop`）。閉じた時に、出ている間
  /// true に上書きしていた「アプリが戻るを受ける」を本来の値へ戻す
  /// （[OnboardingPage] の `_claimBack`）。
  final bool Function()? canPopUnderneath;

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  /// **最初のフレームより前に決める。** 起動後に判定すると、本体が一瞬見えて
  /// からオンボーディングが被さる。
  late bool _show = !ref.read(onboardingDoneProvider);

  @override
  Widget build(BuildContext context) {
    final child = widget.child ?? const SizedBox.shrink();
    if (!_show) return child;

    return Stack(
      children: [
        // **下の本体は読み上げからも外す。** 上に重ねてタップを止めるだけだと、
        // スクリーンリーダーの activate は `SemanticsAction.tap` を直に送るので
        // **ヒットテストを迂回して発火し**、オンボーディングが出たままホームの
        // タブや記事カードへ到達して開けてしまう（利用者からは何が起きたのか
        // 分からない）。`AppShell` の暗幕（メニューのシート）と同じ扱い。
        //
        // **ここに来る時点で `_show` は必ず true**（上で早期に返している）。
        ExcludeSemantics(child: child),
        OnboardingPage(
          backButtonDispatcher: widget.backButtonDispatcher,
          onDone: () {
            // **見せたことを先に残す。** 閉じる前に落ちても二度は出さない。
            // ここで広告の SDK も始まる（`waitForOnboarding`）
            ref.read(onboardingDoneProvider.notifier).markDone();
            setState(() => _show = false);
            if (widget.canPopUnderneath case final canPop?) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                NavigationNotification(
                  canHandlePop: canPop(),
                ).dispatch(context);
              });
            }
          },
        ),
      ],
    );
  }
}
