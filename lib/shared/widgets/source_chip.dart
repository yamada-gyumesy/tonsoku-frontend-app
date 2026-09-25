import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/shared/widgets/optical_center.dart';

/// 出典への導線。web の `CmSourceChip`（gyumesy-frontend-app の `SourceChip` を写した）。
/// 枠線だけの丸いチップに「公式」と外部リンクの記号。
///
/// **配信データの `source_label` を出さない。** 全ロケールで日本語のまま届くので、
/// 英語版でタイトルだけ英語・出典だけ日本語という状態になる。web も固定語
/// （公式 / Official / 官方）を出している。
///
/// **松屋のアイコンは出さない**（web の `CmSourceChip` の注記。松のやと松屋は
/// 別ブランドで、意匠を持ち込まない）。
///
/// **http / https 以外は出さない**（[safeUrl]）。
class SourceChip extends ConsumerWidget {
  const SourceChip({required this.url, super.key});

  /// [safeUrl] を通した URL。
  final String url;

  /// 導線にしてよい URL か。web の `safeExternalUrl`。
  ///
  /// 配信の `source_url` は**こちらの管理下に無い値**なので、形を見てから使う
  /// （web: `javascript:` が入るとブラウザで実行される。アプリでも OS に
  /// 任意の scheme を渡すことになる）。**null なら導線を出さない。**
  static String? safeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAuthority) return null;
    return uri.scheme == 'http' || uri.scheme == 'https' ? url : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);

    return Semantics(
      link: true,
      child: GestureDetector(
        onTap: () =>
            launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView),
        child: Container(
          // web の `px-1.5 py-0.5 rounded-full border border-brand-border bg-brand-surface`
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // **字面を器の中央に寄せる。** アイコンを下げるのではなく文字を
              // 上げる（web の `optical-center` と同じ向き。gyumesy と同じ）
              OpticalCenter(
                fontSize: 10,
                child: Text(
                  t.commonOfficial,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.2,
                    color: colors.textSub,
                  ),
                ),
              ),
              // web の `gap-1`
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new,
                size: 11,
                // web の `opacity-60`
                color: colors.textSub.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
