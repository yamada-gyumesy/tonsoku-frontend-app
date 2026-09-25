import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';

/// 画像を全画面で開く。web の `CoImageViewer`（記事の画像・クーポンの QR コードと
/// チラシ）。
///
/// 記事の画像は告知画像や投稿のスクリーンショットが多く、**小さく写った文字を
/// 読みたい場面がある**。アプリの本文は画面ごと拡大できないので、その代わりの導線。
///
/// - [isCode] … **券売機にかざす QR コード。** 「券売機にかざしてください」の一言を
///   添え、**読み取れる大きさ以上には広げない**（web の `is-code` は 24rem が上限。
///   それ以上大きくしても意味が無い）
/// - [source] … **絵の引用元**（チラシ）。**行のチップにはせず、開いた面にだけ出す**
///   （券売機の前で押してほしいものと競合する。web のユーザー指摘）
Future<void> showImageViewer(
  BuildContext context, {
  required String url,
  required String alt,
  bool isCode = false,
  ({String url, String label})? source,
}) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder<void>(
    opaque: false,
    // web の `bg-black/85`
    barrierColor: const Color(0xD9000000),
    pageBuilder: (context, _, _) =>
        _ImageViewer(url: url, alt: alt, isCode: isCode, source: source),
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  ),
);

class _ImageViewer extends ConsumerWidget {
  const _ImageViewer({
    required this.url,
    required this.alt,
    required this.isCode,
    required this.source,
  });

  final String url;
  final String alt;
  final bool isCode;
  final ({String url, String label})? source;

  /// QR コードの上限（web の `max-width: 24rem`）。
  static const _codeMax = 384.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final source = this.source;
    final sourceUri = source == null ? null : Uri.tryParse(source.url);
    Widget image = Semantics(
      label: alt.isEmpty ? t.imageViewerLabel : alt,
      image: true,
      child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
    );
    if (isCode) {
      image = ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _codeMax,
          maxHeight: _codeMax,
        ),
        child: image,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // 画像の外側をタップしても閉じられるようにする（閉じるボタンを
            // 探させない）
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  // web の `p-4 gap-3`
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: isCode ? 1 : 5,
                          child: Center(child: image),
                        ),
                      ),
                      if (isCode) ...[
                        const SizedBox(height: 12),
                        Text(
                          t.imageViewerCodeNote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      if (source != null && sourceUri != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => launchUrl(
                            sourceUri,
                            mode: LaunchMode.inAppBrowserView,
                          ),
                          child: Text(
                            '${t.commonQuoteSource}: ${source.label}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xCCFFFFFF),
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xCCFFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: t.commonClose,
                icon: const Icon(Icons.close),
                color: Colors.white,
                style: IconButton.styleFrom(
                  // web の `bg-black/60 rounded-full`
                  backgroundColor: const Color(0x99000000),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
