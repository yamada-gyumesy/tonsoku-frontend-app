import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:tonsoku/core/router/app_router.dart';

/// 記事から戻る。**戻り先が無ければホームへ**。
///
/// 通知やユニバーサルリンクで記事を直接開いた時は積んだ画面が無く、
/// `maybePop()` だけだと押しても何も起きない。ヘッダーの「＜ 戻る」と
/// 末尾の「一覧に戻る」で判定が食い違わないよう、ここに 1 つだけ置く。
void backFromArticle(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  context.go(AppRoutes.home);
}
