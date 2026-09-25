import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/analytics/analytics.dart';
import 'package:tonsoku/core/analytics/screen_path.dart';

/// 画面を見たことを送る。gyumesy-frontend-app の同名のものを写した。
///
/// **見えるようになるたびに送る。** web は遷移のたびに Pageview が立つので、
/// **パスの文字列が揃っていても件数の意味が違えば突き合わせられない**。
///
/// タブは `IndexedStack` で生き続ける（`build` は 1 回きり）ので、
/// **`TickerMode` で「いま表になっているか」を見る** —— go_router の
/// `StatefulShellRoute.indexedStack` は、裏のブランチを
/// `Offstage` ＋ `TickerMode(enabled: false)` で包んでいる。
///
/// 積んだ画面（記事・メニューから開く画面）は上に何か載ると `TickerMode` が落ちるので、
/// 戻ってきた時も送られる。
///
/// **同じ画面を続けて 2 回送らない。** スクロールや再描画では送らず、
/// 「隠れて → また出た」か「送る中身が変わった」時だけ送る。
///
/// **オンボーディング中は、下のホームも数えられる**（初回起動の 1 回だけ）。
/// [OnboardingOverlay] は重ねているだけなので、下の `TickerMode` は生きたまま。
/// 初回起動の件数を GA4 で読む時に効く。
class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({required this.screen, required this.child, super.key});

  /// 送る中身。**まだ決まっていなければ `null`**（記事の表題待ちなど）。
  final ScreenPath? screen;
  final Widget child;

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  ScreenPath? _sent;
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final visible = TickerMode.valuesOf(context).enabled;
    final screen = widget.screen;

    if (!visible) {
      // 隠れたら「送った」を忘れる。次に出た時にまた送る
      _visible = false;
      _sent = null;
    } else if (screen != null && (!_visible || screen != _sent)) {
      _visible = true;
      _sent = screen;
      // **build の最中に送らない**（provider を読むと build 中の変更になる）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(analyticsProvider).screen(screen);
      });
    }
    return widget.child;
  }
}
