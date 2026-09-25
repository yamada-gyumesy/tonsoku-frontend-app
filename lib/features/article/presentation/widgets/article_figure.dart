import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/config/app_config_provider.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/article/domain/article_body.dart';
import 'package:tonsoku/features/article/presentation/widgets/image_viewer.dart';

/// 本文中の画像と、その出所。web の `markdown.css` の `figure` / `figcaption`:
///
/// - 画像は中央寄せで**最大 480px**（`max-width: min(100%, 480px)`）、角丸 8px
/// - 下に 24px（`figure { margin: 1.5rem 0 }`。上は直前の段落の余白に任せる）
/// - 出所は**右寄せ**の 12px・副テキスト色。**リンクも同じ色で下線なし**
///   （出所は強調ではなく注記。矢印も出さない）
///
/// **押すと全画面で開く**（web の `CoImageViewer` と同じ。記事の画像は告知画像や
/// 投稿のスクリーンショットが多く、小さく写った文字を読みたい場面がある）。
class ArticleFigure extends ConsumerWidget {
  const ArticleFigure({required this.figure, super.key});

  final FigureBlock figure;

  static const _maxWidth = 480.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      // **上は持たない。** web は `figure { margin: 1.5rem 0 }` だが、縦の余白が
      // 直前の段落の下（30）と相殺されて 30 になる。Flutter は足し算になるので、
      // 上を持つと 54 空く（見出しの余白と同じ事情。`article_markdown.dart`）
      padding: const EdgeInsets.only(bottom: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            // **`stretch` にしない。** 最大幅まで引き伸ばすと、小さい画像が
            // 480px まで拡大されてぼやける（gyumesy と同じ）
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _Image(url: figure.url, alt: figure.alt),
              ),
              if (figure.hasCaption) ...[
                const SizedBox(height: 8),
                // 出所は右寄せなので、画像の幅ではなく枠の幅いっぱいに敷く
                SizedBox(
                  width: double.infinity,
                  child: _Caption(figure: figure),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Image extends ConsumerWidget {
  const _Image({required this.url, required this.alt});

  final String url;
  final String alt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(appConfigProvider).cdnUrl(url);
    final colors = context.colors;
    // 読み込み中だけ場所を取る。**配信は画像の寸法を持たない**ので、
    // 告知画像に多い横長（4:3）で仮置きする
    final placeholder = AspectRatio(
      aspectRatio: 4 / 3,
      child: ColoredBox(color: colors.bg),
    );

    return Semantics(
      label: alt.isEmpty ? null : alt,
      image: true,
      button: true,
      child: GestureDetector(
        onTap: () => showImageViewer(context, url: resolved, alt: alt),
        child: CachedNetworkImage(
          imageUrl: resolved,
          // **元の比率のまま出す。** 枠の比率に合わせて切ると、縦長の告知画像で
          // 上下が落ちて肝心の部分が見えなくなる
          imageBuilder: (context, provider) =>
              Image(image: provider, fit: BoxFit.contain),
          placeholder: (context, _) => placeholder,
          errorWidget: (context, _, _) => placeholder,
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.figure});

  final FigureBlock figure;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = TextStyle(fontSize: 12, height: 1.5, color: colors.textSub);
    final text = [
      figure.captionText,
      figure.captionLinkText,
    ].where((s) => s.isNotEmpty).join(' ');

    final caption = Text(text, textAlign: TextAlign.right, style: style);
    final uri = figure.hasLink ? Uri.tryParse(figure.captionUrl) : null;
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return caption;
    }

    return GestureDetector(
      onTap: () => launchUrl(uri, mode: LaunchMode.inAppBrowserView),
      child: caption,
    );
  }
}
