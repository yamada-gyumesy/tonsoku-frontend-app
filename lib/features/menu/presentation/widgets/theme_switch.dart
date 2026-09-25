import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/theme/theme_mode_controller.dart';

/// 外観モードの切り替え。web の `CmThemeSwitch` と同じスライド式。
///
/// **OS 追従の間も、いま効いている側につまみを出す。** どちらにも付いていないと
/// 壊れた操作部に見える。画面が実際にライトなら「ライト」に付いているのが正しく、
/// 追従をやめる操作はそのまま押すこと。
///
/// web も同じ（`CmThemeSwitch` は `syncRadios(currentTheme())` のあと
/// `thumb.style.opacity = '1'` にする。初期クラスの `opacity-0` は JS が走る前の
/// 状態で、選択の有無ではない）。
///
/// **どこを押しても逆側へ移る。** 選択中のセグメントを押しても反応する
/// （web と同じ。トグルとして扱えるほうが指の運びが短い）。
class ThemeSwitch extends ConsumerWidget {
  const ThemeSwitch({super.key});

  /// セグメント 1 つぶんの大きさ。web の `p-1.5` + `text-[18px]`。
  static const _segment = 30.0;

  /// 器の内側の余白。web の `p-0.5`。
  static const _padding = 2.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final mode = ref.watch(themeModeControllerProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // OS 追従の時は、いま効いているほうを選択状態として出す
    final selected = switch (mode) {
      ThemeMode.light => 0,
      ThemeMode.dark => 1,
      ThemeMode.system => isDark ? 1 : 0,
    };

    void toggle() {
      // 「いま見えている側」の逆へ移す。OS 追従のままだと、どちらを押しても
      // 同じ側に倒れて押した場所と結果が食い違う
      ref
          .read(themeModeControllerProvider.notifier)
          .set(isDark ? ThemeMode.light : ThemeMode.dark);
    }

    return Semantics(
      label: t.themeLabel,
      value: isDark ? t.themeDark : t.themeLight,
      button: true,
      child: GestureDetector(
        onTap: toggle,
        // 横に払っても切り替わる（web はつまみをドラッグできる）
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity == 0) return;
          ref
              .read(themeModeControllerProvider.notifier)
              .set(velocity > 0 ? ThemeMode.dark : ThemeMode.light);
        },
        child: Container(
          padding: const EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            // web の `bg-black/5 dark:bg-white/5`
            color: (colors.isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                left: selected * _segment,
                top: 0,
                child: Container(
                  width: _segment,
                  height: _segment,
                  decoration: BoxDecoration(
                    // web の `bg-brand-toggle-thumb`。**ライトの反転ではない**
                    // （ダークで同じ色にするとつまみが溝に沈む。`AppColors`）
                    color: colors.toggleThumb,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _icon(Icons.light_mode, selected == 0, colors),
                  _icon(Icons.dark_mode, selected == 1, colors),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _icon(IconData icon, bool active, AppColors colors) => SizedBox(
    width: _segment,
    height: _segment,
    child: Icon(
      icon,
      size: 18,
      // web の `peer-checked:text-brand-toggle-thumb-text`
      color: active ? colors.toggleThumbText : colors.textSub,
    ),
  );
}
