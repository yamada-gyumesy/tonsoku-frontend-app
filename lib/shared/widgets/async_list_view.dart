import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';

/// 取得に失敗した時の表示。
///
/// **「取れなかった」を「無い」に潰さないための部品。** `value ?? const []` と
/// 書くと error が捨てられ、取得失敗なのに「記事がありません」と出る。
/// 基盤の `CdnRepository` が失敗を握り潰さずに流しているのは、ここで区別を
/// 出すためなので、画面側で空に倒すと台無しになる。
class LoadFailure extends ConsumerWidget {
  const LoadFailure({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 32, color: colors.textSub),
          const SizedBox(height: 12),
          Text(
            t.commonError,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.text),
          ),
          const SizedBox(height: 16),
          // **前景は `primaryText`。既定に任せない。** M3 の `OutlinedButton` は
          // 前景を `colorScheme.primary` に落とす。いまは `primary` に
          // `primaryText` を渡しているので同じ色になるが、**`LoadFailure` は
          // 復帰する唯一の導線**なので、テーマの配線が変わっても読める色を
          // ここで固定する（gyumesy はここで 3.51:1 まで落としていた）
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primaryText,
            ),
            child: Text(t.commonRetry),
          ),
        ],
      ),
    );
  }
}

/// 中身が空の時の表示。**取得に成功したうえで 0 件**の時だけ出す。
class EmptyHint extends StatelessWidget {
  const EmptyHint({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: context.colors.textSub),
      ),
    ),
  );
}

/// 初回取得中の表示。**再取得中は出さない**（旧内容を出したまま差し替える）。
class InitialLoading extends StatelessWidget {
  const InitialLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 64),
    child: Center(child: CircularProgressIndicator()),
  );
}
