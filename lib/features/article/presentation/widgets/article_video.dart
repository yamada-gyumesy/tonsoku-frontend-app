import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player/video_player.dart';

import 'package:tonsoku/core/config/app_config_provider.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/shared/models/article.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';

/// 記事の動画（X のポストの添付。記事本体の `videos`）。**配信元は自前の R2 なので
/// アプリ内で再生する**（gyumesy-frontend-app の写し）。
///
/// web も `<video controls playsinline>` でインライン再生している。外部へ
/// 飛ばすと、自前で配信しているものをわざわざ他所で見せることになる。
///
/// **最初から読み込まない。** ポスター画像（配信データが持っている）を出し、
/// 押されてから初期化する。記事を開いただけで数 MB を落とすのは速報を
/// 読みに来た人には重い（web も `preload="none"` で本体は待たせている）。
class ArticleVideoPlayer extends ConsumerStatefulWidget {
  const ArticleVideoPlayer({required this.video, super.key});

  final ArticleVideo video;

  @override
  ConsumerState<ArticleVideoPlayer> createState() => _ArticleVideoPlayerState();
}

class _ArticleVideoPlayerState extends ConsumerState<ArticleVideoPlayer> {
  VideoPlayerController? _controller;
  bool _preparing = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_preparing || _controller != null) return;
    setState(() => _preparing = true);

    final url = ref.read(appConfigProvider).cdnUrl(widget.video.url);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
    } on Object {
      // 再生できない時はポスターのまま残す（記事は読めるので画面は壊さない）
      await controller.dispose();
      if (mounted) setState(() => _preparing = false);
      return;
    }

    if (!mounted) {
      await controller.dispose();
      return;
    }
    await controller.play();
    setState(() {
      _controller = controller;
      _preparing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    // **読み込む前から配信の実寸で場所を取る**（後から高さが決まると本文が飛ぶ）。
    // 寸法は配信側でも必須（揃わない動画は `Article` が落とす）
    final aspectRatio =
        controller?.value.aspectRatio ?? widget.video.aspectRatio;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: controller == null
          ? _Poster(
              posterUrl: widget.video.poster,
              isPreparing: _preparing,
              onTap: _start,
            )
          : _Player(controller: controller),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.posterUrl,
    required this.isPreparing,
    required this.onTap,
  });

  final String posterUrl;
  final bool isPreparing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPreparing ? null : onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CdnImage(url: posterUrl),
          const ColoredBox(color: Color(0x33000000)),
          Center(
            child: isPreparing
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Color(0xE6FFFFFF),
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(
                    Icons.play_circle_fill,
                    size: 56,
                    color: Color(0xE6FFFFFF),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 再生中。**通常のプレイヤーの操作**（再生 / 一時停止・シーク）を出す。
class _Player extends StatefulWidget {
  const _Player({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> {
  /// 操作を出しているか。再生中は自動で引っ込め、触ると戻す。
  bool _showControls = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final colors = context.colors;

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(controller),
          // 進捗バーは常に出す（どこまで見たかは操作を出していなくても要る）
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                // 動画の上に載るので地の上の赤（`primaryText`）を使う
                playedColor: colors.primaryText,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
          if (_showControls)
            ColoredBox(
              color: const Color(0x33000000),
              child: Center(
                child: ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: controller,
                  builder: (context, value, _) => IconButton(
                    iconSize: 56,
                    color: const Color(0xE6FFFFFF),
                    icon: Icon(
                      value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                    ),
                    onPressed: () => value.isPlaying
                        ? controller.pause()
                        : controller.play(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
