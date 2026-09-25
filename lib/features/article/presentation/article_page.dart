import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/config/app_config.dart';
import 'package:tonsoku/core/config/app_config_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/article/domain/article_body.dart';
import 'package:tonsoku/features/article/domain/article_body_parser.dart';
import 'package:tonsoku/features/article/domain/successor_lookup.dart';
import 'package:tonsoku/features/article/presentation/widgets/article_figure.dart';
import 'package:tonsoku/features/article/presentation/widgets/article_hero.dart';
import 'package:tonsoku/features/article/presentation/widgets/article_markdown.dart';
import 'package:tonsoku/features/article/presentation/widgets/article_table.dart';
import 'package:tonsoku/features/article/presentation/widgets/article_video.dart';
import 'package:tonsoku/features/article/presentation/widgets/back_to_list.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/home/data/article_repository.dart';
import 'package:tonsoku/features/home/presentation/header_hide_controller.dart';
import 'package:tonsoku/features/home/presentation/widgets/article_card.dart';
import 'package:tonsoku/shared/models/article.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/utils/character.dart';
import 'package:tonsoku/shared/utils/pull_to_refresh.dart';
import 'package:tonsoku/shared/widgets/async_list_view.dart';
import 'package:tonsoku/shared/widgets/back_header.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';
import 'package:tonsoku/shared/widgets/label_chip.dart';
import 'package:tonsoku/shared/widgets/section_heading.dart';

/// 記事詳細。**web の `src/pages/[...locale]/articles/[slug].astro` と同じ並び。**
///
/// ヘッダー（サムネ・表題・日時・分類・共有）→ 仮訳の断り → 後継記事の帯 →
/// 動画 → TikTok → 本文 → のや子のひとこと → 関連記事。
///
/// **記事本体（`articles/{slug}.json`）だけで組み立てる。** 一覧を経由せずに
/// 開けるようにするため（関連記事・通知から直接開いた記事）。
///
/// ## この画面にまだ無いもの
///
/// - **広告**（web の `CoAdSlot` 3 枠）… 広告の Issue（#5）
/// - **この記事の前後の予定**（web の `CoCalendarSection`）… カレンダーと一緒に
///   メニューの Issue（#4）
/// - **アプリの案内**（web の `CoAppDownload`）… アプリの中では出さない
///   （アプリを入れた人に「アプリを入れよう」と言うことになる）
/// - **X の返信**（web の `CoXComments`）… 持たない（gyumesy と同じく UGC 判定を避ける）
class ArticlePage extends ConsumerStatefulWidget {
  const ArticlePage({
    required this.slug,
    required this.onOpenArticle,
    super.key,
  });

  final String slug;
  final ValueChanged<String> onOpenArticle;

  @override
  ConsumerState<ArticlePage> createState() => _ArticlePageState();

  /// 共有の中身。**組み立てだけを切り出してある**（`SharePlus.instance` を
  /// 差し替えられないので、ここを直接テストする。gyumesy と同じ）。
  ///
  /// **Web 版の URL を渡す**（アプリを入れていない人にも開けるため）。
  /// **表題と URL を別々に渡し、`title` と `subject` の両方に表題を載せる**
  /// （`subject` が無いと Gmail へ共有した時に件名が空になる。gyumesy の注記）。
  @visibleForTesting
  static ShareParams shareParamsFor({
    required AppConfig config,
    required AppLocale locale,
    required ArticleMeta meta,
  }) => ShareParams(
    title: meta.title,
    subject: meta.title,
    uri: Uri.parse(config.siteUrl('/articles/${meta.slug}/', locale)),
  );
}

class _ArticlePageState extends ConsumerState<ArticlePage> {
  /// **web と同じく、送るとヘッダーが退く。** 記事は縦に長い画面で、読んでいる
  /// 間ずっと戻る導線に高さを取られる必要がない。
  late final _headerHidden = HeaderHideController(maxHidden: BackHeader.height);

  @override
  void dispose() {
    _headerHidden.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final article = ref.watch(articleProvider(widget.slug));
    final value = article.value;
    final colors = context.colors;
    final topInset = MediaQuery.paddingOf(context).top + BackHeader.height;

    final content = switch ((value, article.hasError)) {
      // 前回値が無いまま失敗した時だけエラー画面。**「取れなかった」を
      // 空の記事として出さない**
      (null, true) => Padding(
        padding: EdgeInsets.only(top: topInset),
        child: LoadFailure(
          onRetry: () => ref.invalidate(articleProvider(widget.slug)),
        ),
      ),
      (null, false) => Padding(
        padding: EdgeInsets.only(top: topInset),
        child: const InitialLoading(),
      ),
      (final Article loaded, _) => _Body(
        article: loaded,
        // **ヘッダーぶんの余白はスクロールする側が持つ。** 外側に置くと、
        // ヘッダーが縮んだ時にその余白だけが空の帯として残る（gyumesy と同じ）
        topInset: topInset,
        onOpenArticle: widget.onOpenArticle,
      ),
    };

    return Scaffold(
      backgroundColor: colors.page,
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: _headerHidden.handleScroll,
        child: Stack(
          children: [
            // **本文は選べるようにする**（引用して人に送る・検索する、が読み物では
            // 普通に起きる。`SelectionArea` なら見出し・表・引用まで通しで選べて、
            // リンクはそのまま押せる。gyumesy と同じ）
            SelectionArea(child: content),
            ValueListenableBuilder<double>(
              valueListenable: _headerHidden,
              builder: (context, hidden, _) => Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BackHeader(
                  hidden: hidden,
                  onBack: () => backFromArticle(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.article,
    required this.topInset,
    required this.onOpenArticle,
  });

  final Article article;
  final double topInset;
  final ValueChanged<String> onOpenArticle;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _reloading = false;

  /// 引っ張って更新。**記事も取り直せるようにする** —— 誤字の直しや追記が入った
  /// 時に、アプリを開き直さないと古いままになる（gyumesy と同じ）。
  Future<void> _reload() async {
    if (_reloading) return;
    _reloading = true;
    try {
      final slug = widget.article.meta.slug;
      await pullToRefresh(
        context,
        warm: (c) => c.read(articleRepositoryProvider).refreshArticle(slug),
        reattach: (c) => c.invalidate(articleProvider(slug)),
      );
    } finally {
      _reloading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final meta = article.meta;
    final t = ref.watch(messagesProvider);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final tags = ref.watch(tagsProvider).value ?? const [];
    final successorSlug = SuccessorLookup.resolve(
      article: meta,
      feed: ref.watch(feedProvider).value,
    );
    final blocks = ArticleBodyParser.parse(article.content);
    final related = meta.relatedArticles
        .where((slug) => slug != meta.slug)
        .toList(growable: false);

    // 本文は左右に余白を持たせるが、**サムネイルだけは画面幅いっぱい**に出す
    // （web も SP では画像を紙面の左右いっぱいに出す）
    Widget inset(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );

    return RefreshIndicator(
      edgeOffset: widget.topInset,
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: widget.topInset,
          // web の `pb-10`
          bottom: MediaQuery.paddingOf(context).bottom + 40,
        ),
        children: [
          ArticleHero(meta: meta),
          // web の `px-4 py-5`
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: _Heading(meta: meta, categories: categories, tags: tags),
          ),
          // **仮訳の断り。** 表題の直後、本文より前（読み始める前に断らないと
          // 意味が無い）。**日本語では文言が空なので出ない**
          if (article.isProvisionalTranslation &&
              t.articleProvisionalTranslation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _Notice(text: t.articleProvisionalTranslation),
            ),
          // **後継記事の帯は表題・サムネの直下、本文より前。** まず表題で「この
          // 話題で合っている」と確認させてから最新版を差し出す（web と同じ）
          if (successorSlug != null)
            inset(
              _SuccessorBanner(
                slug: successorSlug,
                onTap: () => widget.onOpenArticle(successorSlug),
              ),
            ),
          // **動画は本文の直前**（web の `CoArticleVideos`）
          for (final (i, video) in article.videos.indexed) ...[
            if (i > 0) const SizedBox(height: 16),
            inset(_VideoBox(video: video)),
          ],
          // **同じく本文の直前。** X 起点と TikTok 起点は別の記事なので、上の
          // 動画とここが同時に出ることは無い
          if (article.tiktok case final tiktok? when tiktok.isPlayableVideo)
            inset(_TikTokFacade(tiktok: tiktok)),
          const SizedBox(height: 24),
          for (final block in blocks)
            switch (block) {
              MarkdownBlock(:final markdown) => inset(
                ArticleMarkdown(markdown: markdown),
              ),
              TableBlock(:final markdown) => inset(
                ArticleTable(markdown: markdown),
              ),
              FigureBlock() => inset(ArticleFigure(figure: block)),
            },
          if (meta.editorComment.isNotEmpty)
            inset(
              _EditorComment(
                comment: meta.editorComment,
                expression: meta.expression,
              ),
            ),
          // **関連記事。0 件は普通にある**（空の見出しを残さない。解決できない
          // 記事はカードごと出ないので、全部解決できなかった時も見出しを消す）
          if (related.isNotEmpty)
            _RelatedArticles(
              slugs: related,
              onOpenArticle: widget.onOpenArticle,
            ),
        ],
      ),
    );
  }
}

/// 表題・日時・分類・共有（web の `CoArticleHeader` のテキスト列）。
///
/// **導入文（description）は出さない。** 本文の 1 段落目が同じ内容を言い直すことが
/// 多く、同じ話を 2 回読ませることになる（web と同じ判断）。
class _Heading extends ConsumerWidget {
  const _Heading({
    required this.meta,
    required this.categories,
    required this.tags,
  });

  final ArticleMeta meta;
  final List<Category> categories;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final locale = ref.watch(localeControllerProvider);
    final t = ref.watch(messagesProvider);
    final categorySlug = meta.categories.firstOrNull;
    final category = categorySlug == null
        ? null
        : categories.where((c) => c.slug == categorySlug).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            meta.title,
            // web の `text-lg leading-normal tracking-[0.04em]`
            style: TextStyle(
              fontSize: 18,
              height: 1.5,
              letterSpacing: 18 * 0.04,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 詳細は絶対表記（web の `formatDateTime`・Asia/Tokyo）
                  Text(
                    formatArticleDateTime(meta.createdAt, locale),
                    style: TextStyle(fontSize: 12, color: colors.textSub),
                  ),
                  const SizedBox(height: 8),
                  // **一覧と違って折り返す**（記事ページは 1 件しか出ないので、
                  // 高さがばらついても並びが崩れる相手がいない。web と同じ）
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (category != null)
                        LabelChip.category(
                          label: category.label,
                          slug: category.slug,
                        ),
                      for (final slug in meta.tags)
                        LabelChip.tag(
                          label:
                              tags
                                  .where((t) => t.slug == slug)
                                  .map((t) => t.label)
                                  .firstOrNull ??
                              slug,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ShareButton(
              tooltip: t.commonShareArticle,
              onPressed: () => SharePlus.instance.share(
                ArticlePage.shareParamsFor(
                  config: ref.read(appConfigProvider),
                  locale: ref.read(localeControllerProvider),
                  meta: meta,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 仮訳の断り。**見た目は法務ページの断りと同じ**（web: 同じ性質の一文が 2 つの面で
/// 違う見え方をすると、読み手には別のものに見える）。
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, height: 1.625, color: colors.textSub),
      ),
    );
  }
}

/// 後継記事への導線。web の `CoArticleSuccessor`。
///
/// **「この記事が古い」ではなく「新しいものがある」と言う。** 読んでいるページを
/// 否定すると、探しものが合っているか分からないまま追い出すことになる。
///
/// **地は `hover`、枠は罫の色**（web の `border-brand-border bg-brand-hover`）。
/// **押せることは表題の下線で示す**（行末の「>」も置かない）。
class _SuccessorBanner extends ConsumerWidget {
  const _SuccessorBanner({required this.slug, required this.onTap});

  final String slug;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final locale = ref.watch(localeControllerProvider);
    // **解決できるまで帯ごと出さない。** 見出しだけ先に出すと、翻訳が無い
    // ロケールで空の帯が押せてしまい、開いた先が取得失敗になる（gyumesy と同じ）
    final meta = ref.watch(articleMetaProvider(slug)).value;
    if (meta == null) return const SizedBox.shrink();

    return Padding(
      // web の `mb-5`
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: colors.hover,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 帯全体の見出し。サムネの右に入れると表題の前置きに見えるので
                // 全幅で 1 行目に置く
                Text(
                  t.articleSuccessor,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textSub,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CdnImage(
                        url: meta.thumbnailSmall,
                        width: 64,
                        height: 48,
                        fallbackAsset: CdnImage.defaultThumbnail,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.375,
                              letterSpacing: 14 * 0.04,
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                              decoration: TextDecoration.underline,
                              decorationColor: colors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // **相対表示にしない。**「最新の記事があります」と
                          // 言いながら「24日前」と出ると、最新に見えない
                          Text(
                            formatDateOnly(meta.createdAt, locale),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 記事の動画 1 本。**高さに上限を掛ける**（web の `max-h-[70svh]`。縦長の動画を
/// 幅いっぱいに出すと高さが 1 画面を超え、上端と操作を同時に見られない）。
class _VideoBox extends StatelessWidget {
  const _VideoBox({required this.video});

  final ArticleVideo video;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxHeight * video.aspectRatio,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ArticleVideoPlayer(video: video),
        ),
      ),
    );
  }
}

/// TikTok の動画。**アプリでは埋め込まず、押したら投稿をアプリ内ブラウザで開く。**
///
/// web は押されるまでポスターを出し、押されたら TikTok の埋め込みに差し替える
/// （開いた瞬間にサードパーティ JS を走らせないため）。アプリで埋め込むには
/// WebView が要り、同じ「押されるまで読み込まない」を保つなら、投稿そのものを
/// 開くのと体験が変わらない。
class _TikTokFacade extends ConsumerWidget {
  const _TikTokFacade({required this.tiktok});

  final ArticleTikTok tiktok;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final label = ref.watch(messagesProvider).articleTiktokPlay;
    final uri = Uri.tryParse(tiktok.postUrl);

    return Center(
      child: ConstrainedBox(
        // web の `w-[325px]`（TikTok の札の幅）
        constraints: const BoxConstraints(maxWidth: 325),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: uri == null
                ? null
                : () => launchUrl(uri, mode: LaunchMode.inAppBrowserView),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 9 / 16,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CdnImage(url: tiktok.poster ?? ''),
                      Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            // 写真の上なのでテーマに依らない（web の `bg-black/55`）
                            color: Color(0x8C000000),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 32,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// のや子のひとこと。web の `CoEditorComment`。
///
/// **丸の中はライト・ダークとも白地**（`portrait`）。線画は赤の単色なので、暗地に
/// 置くとほぼ見えない。**枠線は地の上の赤（`primaryText`）**（丸の外側は箱の地なので、
/// そちらから見えないと枠にならない）。
///
/// **この大きさでは 4 つの表情がほとんど見分けられない。** 承知のうえでこの大きさに
/// している（web のユーザー判断:「分かる人が分かればよい」）。**親切心で丸を大きく
/// しないこと。**
class _EditorComment extends ConsumerWidget {
  const _EditorComment({required this.comment, required this.expression});

  final String comment;
  final String? expression;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);

    return Container(
      // web の `mt-12 p-4 rounded-lg bg-brand-primary-soft border-brand-primary/20`。
      // **上は 48 から本文の最後の段落の余白（30）を引く**（web は相殺されて 48。
      // Flutter は足し算になる。`article_markdown.dart` の見出しと同じ事情）
      margin: const EdgeInsets.only(top: 48 - 30),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.portrait,
              shape: BoxShape.circle,
              border: Border.all(color: colors.primaryText),
            ),
            child: ClipOval(
              child: SvgPicture.network(
                expressionUrl(expression),
                // **取れなかった時は白い丸だけ残す**（壊れ画像のアイコンが丸の中に
                // 出るより穏やか。web の `onerror="this.remove()"`）
                errorBuilder: (context, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.articleCharacterComment,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  comment,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.625,
                    color: colors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 関連記事。**一覧と同じカードで並べる**（web と同じ）。
///
/// **各記事の本体を取って解決する**（`articleMetaProvider`）。取れなかった
/// 記事は出さない（題の無い行を置いても押す判断ができない）。**1 本も
/// 解決できなければ見出しごと出さない**（web: 空の見出しを残さない）。
class _RelatedArticles extends ConsumerWidget {
  const _RelatedArticles({required this.slugs, required this.onOpenArticle});

  final List<String> slugs;
  final ValueChanged<String> onOpenArticle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final tags = ref.watch(tagsProvider).value ?? const [];
    final resolved = [
      for (final slug in slugs) ?ref.watch(articleMetaProvider(slug)).value,
    ];
    if (resolved.isEmpty) return const SizedBox.shrink();

    return Padding(
      // web の `mt-14`
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeading(label: t.articleRelated),
          ),
          // **カードは画面幅いっぱいに置く**（左右の余白はカードが持つ）
          for (final meta in resolved)
            ArticleCard(
              article: meta,
              categories: categories,
              tags: tags,
              onTap: () => onOpenArticle(meta.slug),
            ),
        ],
      ),
    );
  }
}

/// 共有の丸ボタン。web の `CmShareButton`（`w-9 h-9 rounded-full border
/// border-brand-border text-brand-text-sub`、アイコン 20px）。
///
/// **記号はプラットフォームで変える。** web も既定は `share`（3 点を結んだ記号）で、
/// Apple 系だけ四角から上向きの矢印に差し替えている（その OS の人が「共有」として
/// 見慣れた記号でないと、押す前に何のボタンか分からない。gyumesy と同じ）。
class ShareButton extends StatelessWidget {
  const ShareButton({
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;

  /// **`Theme.of(context).platform` で見る**（テストから両方の見た目を組めるように）。
  static IconData shareIcon(BuildContext context) =>
      switch (Theme.of(context).platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => Icons.ios_share,
        _ => Icons.share,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          shape: CircleBorder(side: BorderSide(color: colors.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            highlightColor: colors.hover,
            splashColor: colors.hover,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(shareIcon(context), size: 20, color: colors.textSub),
            ),
          ),
        ),
      ),
    );
  }
}
