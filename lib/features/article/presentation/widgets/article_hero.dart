import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/utils/source_label.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';

/// 記事冒頭のサムネイル。web の `CoArticleHeader` を移したもの。
///
/// **画面幅いっぱいに出す**（web も SP では画像を紙面の左右いっぱいに出す）。
/// 引用元は画像の右下に重ねる。
///
/// **サムネイルの無い記事では何も出さない**（既定の絵を差し込むと、それが主役に
/// なる。web も一覧でだけ既定の絵に落とす）。
class ArticleHero extends ConsumerWidget {
  const ArticleHero({required this.meta, super.key});

  final ArticleMeta meta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!meta.hasThumbnail) return const SizedBox.shrink();

    final t = ref.watch(messagesProvider);
    // 引用元の表示先。専用の指定があればそちら、無ければ記事全体の出典。
    // **ラベルとリンク先は同じ URL から作る**（別々にすると「引用元:
    // matsuyafoods.co.jp」と書いてある札が navitime に飛ぶ。web が踏んでいる）
    final sourceUrl = meta.thumbnailSource.isNotEmpty
        ? meta.thumbnailSource
        : meta.sourceUrl;
    final uri = Uri.tryParse(sourceUrl);
    // **http(s) の時だけ出す**（web の `safeExternalUrl`。配信の URL は
    // こちらの管理下に無い）。ホスト名をそのまま出さない（登録ドメインを出す）
    final label = uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
        ? sourceLabelOf(sourceUrl) ?? ''
        : '';

    // **高さの上限を幅の 75% にする**（web の `max-height: 75cqi`）。
    // 縦長の投稿画像をそのまま出すと、画面がサムネイルだけで埋まって
    // 表題が見えないまま始まる
    final width = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // **一覧の小サイズ版ではなく原寸を使う。** ここは主役なので、
        // 200px 幅の画像を引き伸ばすと粗さが出る
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: width * 0.75),
          child: CdnImage(
            url: meta.thumbnail,
            alt: meta.title,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (label.isNotEmpty)
          Positioned(
            right: 4,
            bottom: 4,
            child: GestureDetector(
              onTap: () => launchUrl(uri!, mode: LaunchMode.inAppBrowserView),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                // **写真の上に載るのでテーマに依らない**（web の `text-white/90
                // bg-black/60`）。gyumesy の値（black/40・white/80）では、とん速の
                // 写真（白や黄の地が多い公式のお知らせ画像）の上で 4.5:1 に届かない
                // ―― 地が純白でも 5.02:1 になる値を web が選んでいる
                decoration: BoxDecoration(
                  color: const Color(0x99000000),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${t.commonQuoteSource}: $label',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xE6FFFFFF),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
