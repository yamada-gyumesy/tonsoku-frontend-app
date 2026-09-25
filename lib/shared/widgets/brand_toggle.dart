import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';

/// web の `CmToggle` と同じ見た目のトグル（gyumesy-frontend-app の `BrandToggle` を
/// 写し、色を web のとん速版に置き換えた）。
///
/// **`Switch` を使わない。** Material 3 のスイッチは**オフの時につまみが
/// small dot まで縮む**ので、押せるものに見えない。web は**オンでもオフでも
/// 同じ大きさのつまみ**。
///
/// **自分では押されない。** 押すのは行全体（`NotificationToggleRow`）の仕事で、
/// ここは状態を描くだけ。指で触る的は行の大きさが担う。
///
/// ## 色（web の `CmToggle` の注記が正）
///
/// - **OFF の溝は [AppColors.textSub]。** 罫線色だと面に対して 1.32:1 で、
///   意味を持つ非テキストの 3:1 を割る（トグルは形が見えないと状態が分からない）
/// - **ON の溝は [AppColors.primaryText]。塗りの `primary` を使わない**
///   （ダークの面に対して 2.75:1 しか出ない。ライトでは 7.20:1 出るので、
///   ライトだけ見ていると気づけない）
/// - つまみは面色（[AppColors.surface]）に罫線色の縁。ON では縁を面色に溶かす
class BrandToggle extends StatelessWidget {
  const BrandToggle({required this.value, super.key});

  final bool value;

  /// web の `w-11 h-6`
  static const _trackWidth = 44.0;
  static const _trackHeight = 24.0;

  /// web の `after:h-5 after:w-5` と `after:top-[2px] after:left-[2px]`
  static const _knob = 20.0;
  static const _inset = 2.0;

  /// web の `transition-all`（Tailwind の既定）
  static const _duration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // web: `bg-brand-text-sub` / `peer-checked:bg-brand-primary-text`
    final track = value ? colors.primaryText : colors.textSub;
    // web: `after:border-brand-border` / `peer-checked:after:border-brand-surface`
    final knobBorder = value ? colors.surface : colors.border;

    return SizedBox(
      width: _trackWidth,
      height: _trackHeight,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: _duration,
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(_trackHeight / 2),
            ),
          ),
          AnimatedPositioned(
            duration: _duration,
            top: _inset,
            // web の `peer-checked:after:translate-x-full`（つまみ 1 つぶん）
            left: value ? _inset + _knob : _inset,
            child: Container(
              width: _knob,
              height: _knob,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: knobBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
