import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';

/// 積んだ画面の「＜ 戻る」。
///
/// **矢印だけにしない。** web はヘッダーのロゴを「＜ 戻る」に差し替えていて、
/// 言葉が付いていることが意匠の一部。既定の `BackButton` は矢印だけで、
/// 同じアプリの他の画面と揃わない。
///
/// **題は出さない。** 題は本文の見出しが担う（記事も通知設定も、本文の
/// 1 行目に見出しがある）。
class BackLeading extends ConsumerWidget {
  const BackLeading({this.onPressed, super.key});

  /// 押した時の動き。省くと 1 つ戻すだけ。
  final VoidCallback? onPressed;

  /// `AppBar.leadingWidth` に渡す幅。**「戻る」の文字が入る幅が要る**
  /// （既定の 56 だと英語の `Back` で切れる）。
  static const width = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    return TextButton.icon(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_ios, size: 18),
      label: Text(t.commonBack, style: const TextStyle(fontSize: 14)),
      style: TextButton.styleFrom(
        foregroundColor: context.colors.text,
        padding: const EdgeInsets.only(left: 8),
      ),
    );
  }
}
