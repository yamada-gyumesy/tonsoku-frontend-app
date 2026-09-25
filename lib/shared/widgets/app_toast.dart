import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';

/// 画面上端に出す短い通知。**web の `CaToast` と同じ見た目・同じ位置。**
/// gyumesy-frontend-app の `AppToast` を写し、色を web のとん速版に置き換えた。
///
/// `SnackBar` を使わない理由は**下端がタブバーで埋まっている**こと。web は
/// `top-4` に出しており、そこに合わせる。
class AppToast {
  const AppToast._();

  static const _duration = Duration(seconds: 3);
  static const _fade = Duration(milliseconds: 300);

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) =>
          _Toast(message: message, isError: isError, onDone: entry.remove),
    );
    overlay.insert(entry);
  }
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.message,
    required this.isError,
    required this.onDone,
  });

  final String message;
  final bool isError;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // **最初のフレームの後で立ち上げる。** 同じフレームで `true` にすると
    // 変化が無いことになり、フェードが飛ぶ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    Future.delayed(AppToast._duration, () {
      if (!mounted) return;
      setState(() => _visible = false);
      Future.delayed(AppToast._fade, widget.onDone);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // **web（とん速版の `CaToast`）に合わせる。** エラーは塗りの赤に白
    // （`bg-brand-primary text-brand-on-primary`）、通常は本文色を反転した面
    // （`bg-brand-text text-brand-surface`）。gyumesy の `bg-red-600` は
    // とん速の配色に無い色なので写さない
    final background = widget.isError ? colors.primary : colors.text;
    final foreground = widget.isError ? colors.onPrimary : colors.surface;

    return Positioned(
      // web は `top-4`。**セーフエリアの下に潜らせない**
      top: MediaQuery.paddingOf(context).top + 16,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: AppToast._fade,
          child: AnimatedSlide(
            offset: Offset(0, _visible ? 0 : -0.25),
            duration: AppToast._fade,
            child: Align(
              child: Material(
                color: background,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: Padding(
                  // web は `px-4 py-2.5`
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    widget.message,
                    style: TextStyle(fontSize: 14, color: foreground),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
