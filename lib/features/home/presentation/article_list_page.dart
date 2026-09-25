import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/article/presentation/widgets/back_to_list.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/home/domain/article_filter.dart';
import 'package:tonsoku/features/home/presentation/widgets/article_card.dart';
import 'package:tonsoku/features/home/presentation/widgets/article_card_skeleton.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/widgets/async_list_view.dart';
import 'package:tonsoku/shared/widgets/back_header.dart';
import 'package:tonsoku/shared/widgets/section_heading.dart';

/// 記事一覧（ホームの「過去の記事を見る」の行き先）。web の `/articles/`。
///
/// **カテゴリとタグで絞れる**（[ArticleFilter]）。TOP からカテゴリのタブ列を
/// 外したので、その代わり（web と同じ）。
///
/// **全件を 1 枚に出す**（`articles/index.json`。記事はまだ数十本）。
///
/// ## ヘッダーは退かない（web との差）
///
/// web はどのページでもヘッダーがスクロールで退き、絞り込みの帯がそれに付いて
/// 上端まで上がる（`utils/sticky.ts` の `bindBand`）。アプリでは**帯を
/// スリバーで貼り付けている**ので、ヘッダーの退避に帯を追随させると、帯の
/// 貼り付き位置をスクロールと別に動かし続けることになる。**ここはヘッダーを
/// 固定にして、帯はその直下に貼り付くだけにした。**
class ArticleListPage extends ConsumerStatefulWidget {
  const ArticleListPage({required this.onOpenArticle, super.key});

  final ValueChanged<String> onOpenArticle;

  @override
  ConsumerState<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends ConsumerState<ArticleListPage> {
  String? _category;
  final _selectedTags = <String>{};

  /// 帯が上端に貼り付いたか。**貼り付いた時だけ下に区切り線を出す**
  /// （web の `.sticky-band[data-stuck]`）。
  final _stuck = ValueNotifier(false);

  /// 帯の手前に置く番兵（web の `data-article-filter-sentinel`）。**番兵が
  /// 帯の貼り付き位置を過ぎたら貼り付いた**と見る。
  final _sentinel = GlobalKey();
  final _viewport = GlobalKey();

  bool _reloading = false;

  @override
  void dispose() {
    _stuck.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    final sentinel = _sentinel.currentContext?.findRenderObject() as RenderBox?;
    final viewport = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (sentinel == null || viewport == null || !sentinel.attached) {
      return false;
    }
    final y = sentinel.localToGlobal(Offset.zero, ancestor: viewport).dy;
    _stuck.value = y <= 0;
    return false;
  }

  Future<void> _reload() async {
    if (_reloading) return;
    _reloading = true;
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await refreshArchiveLists(container);
    } finally {
      _reloading = false;
    }
  }

  void _selectCategory(String? category) => setState(() {
    _category = category;
    // **カテゴリを替えたらタグの選択は捨てる**（別のカテゴリのタグは見えなく
    // なるため。web と同じ）
    _selectedTags.clear();
  });

  void _toggleTag(String tag) => setState(() {
    if (!_selectedTags.remove(tag)) _selectedTags.add(tag);
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final articles = ref.watch(articleIndexProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value;
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final items = articles.value;

    return Scaffold(
      backgroundColor: colors.page,
      body: Column(
        children: [
          BackHeader(onBack: () => backFromArticle(context)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: CustomScrollView(
                  key: _viewport,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        // web の `px-4 pt-4`。**下の余白は持たない** —— 帯が
                        // 上に 16px 持つ（貼り付いても同じ余白感にするため）
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: SectionHeading(label: t.homeArchiveTitle),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(key: _sentinel)),
                    // **カテゴリが取れないと絞り込みが成立しないので、帯は
                    // 両方揃ってから出す**（gyumesy のホームがカテゴリの失敗を
                    // 記事の失敗と同じに扱っているのと同じ理由）
                    if (items != null && categories != null)
                      _FilterBand(
                        stuck: _stuck,
                        categories: ArticleFilter.presentCategories(
                          items,
                          categories,
                        ),
                        childTags: _category == null
                            ? const []
                            : ArticleFilter.childTags(items, tags, _category!),
                        category: _category,
                        selectedTags: _selectedTags,
                        allLabel: t.filterAll,
                        onSelectCategory: _selectCategory,
                        onToggleTag: _toggleTag,
                      ),
                    ..._body(
                      articles: articles,
                      categoriesAsync: categoriesAsync,
                      categories: categories ?? const [],
                      tags: tags,
                      noArticles: t.commonNoArticles,
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body({
    required AsyncValue<List<ArticleMeta>> articles,
    required AsyncValue<List<Category>> categoriesAsync,
    required List<Category> categories,
    required List<Tag> tags,
    required String noArticles,
  }) {
    final items = articles.value;
    if (items == null || categoriesAsync.value == null) {
      return [
        if (articles.hasError || categoriesAsync.hasError)
          SliverToBoxAdapter(child: LoadFailure(onRetry: _reload))
        else
          const SliverToBoxAdapter(child: ArticleCardSkeleton()),
      ];
    }

    // 配信は `created_at` の降順。**並べ直さない**（web と同じ）
    final filtered = ArticleFilter.apply(
      items,
      category: _category,
      selectedTags: _selectedTags,
    );
    if (filtered.isEmpty) {
      return [SliverToBoxAdapter(child: EmptyHint(message: noArticles))];
    }

    return [
      SliverList.builder(
        itemCount: filtered.length,
        itemBuilder: (context, i) => ArticleCard(
          article: filtered[i],
          categories: categories,
          tags: tags,
          flushTop: i == 0,
          onTap: () => widget.onOpenArticle(filtered[i].slug),
        ),
      ),
    ];
  }
}

/// 絞り込みの帯。**ヘッダー直下に隙間なく貼り付く**（web の `.sticky-band`）。
///
/// - 地は面色。**枠・角丸・影は付けない**（gyumesy の浮いたカードとは違う。
///   web のユーザー指定）
/// - **貼り付いた時だけ下に区切り線を 1 本出す。** 線は紙面の端から端まで
/// - **帯自体に上下 16px を持たせる**（貼り付いても普段と同じ余白感のまま。
///   一覧の 1 件目は上の余白を削って重ねる。`ArticleCard.flushTop`）
class _FilterBand extends StatefulWidget {
  const _FilterBand({
    required this.stuck,
    required this.categories,
    required this.childTags,
    required this.category,
    required this.selectedTags,
    required this.allLabel,
    required this.onSelectCategory,
    required this.onToggleTag,
  });

  final ValueNotifier<bool> stuck;
  final List<Category> categories;
  final List<Tag> childTags;
  final String? category;
  final Set<String> selectedTags;
  final String allLabel;
  final ValueChanged<String?> onSelectCategory;
  final ValueChanged<String> onToggleTag;

  @override
  State<_FilterBand> createState() => _FilterBandState();
}

/// **高さは測ってから貼る**（gyumesy の `MeasuredStickyToolbar` と同じ作り）。
/// 2 段目の出入りと端末の文字サイズで変わるので、決め打ちにできない。
class _FilterBandState extends State<_FilterBand> {
  final _key = GlobalKey();
  double? _height;

  void _measure() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || _height == box.size.height) return;
    if (mounted) setState(() => _height = box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final colors = context.colors;
    final widget = this.widget;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row(
            children: [
              FilterChipButton.all(
                label: widget.allLabel,
                selected: widget.category == null,
                onTap: () => widget.onSelectCategory(null),
              ),
              for (final c in widget.categories)
                FilterChipButton.category(
                  label: c.label,
                  slug: c.slug,
                  selected: widget.category == c.slug,
                  onTap: () => widget.onSelectCategory(c.slug),
                ),
            ],
          ),
          if (widget.childTags.isNotEmpty) ...[
            // web の `gap-2`
            const SizedBox(height: 8),
            _Row(
              children: [
                for (final tag in widget.childTags)
                  TagToggleChip(
                    label: tag.label,
                    selected: widget.selectedTags.contains(tag.slug),
                    onTap: () => widget.onToggleTag(tag.slug),
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    return SliverPersistentHeader(
      pinned: true,
      delegate: _BandDelegate(
        stuck: widget.stuck,
        surface: colors.surface,
        border: colors.border,
        // 測れるまでは 1px で置き、次のフレームで確定させる
        height: _height ?? 1,
        // **中身は常にこの 1 か所に置く**（測る前後で置き場所を変えると
        // `GlobalKey` が同じフレームで 2 か所に現れて中身ごと消える。gyumesy）
        child: KeyedSubtree(key: _key, child: content),
      ),
    );
  }
}

class _BandDelegate extends SliverPersistentHeaderDelegate {
  _BandDelegate({
    required this.stuck,
    required this.surface,
    required this.border,
    required this.height,
    required this.child,
  });

  final ValueNotifier<bool> stuck;
  final Color surface;
  final Color border;
  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ValueListenableBuilder<bool>(
    valueListenable: stuck,
    builder: (context, isStuck, child) => DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        // **線は外側に描く**（web は `box-shadow: 0 1px 0`。`border` だと帯の
        // 高さが 1px 変わり、貼り付く瞬間に下が跳ねる）
        boxShadow: isStuck
            ? [BoxShadow(color: border, offset: const Offset(0, 1))]
            : null,
      ),
      child: child,
    ),
    child: OverflowBox(
      alignment: Alignment.topCenter,
      maxHeight: double.infinity,
      child: child,
    ),
  );

  @override
  bool shouldRebuild(_BandDelegate oldDelegate) =>
      oldDelegate.height != height ||
      oldDelegate.surface != surface ||
      oldDelegate.border != border ||
      oldDelegate.stuck != stuck ||
      // **中身も比べる**（比べないと貼り付いた側が古い選択のまま残る。
      // gyumesy の `StickyToolbar` が実機で踏んでいる）
      oldDelegate.child != child;
}

/// 横に流す 1 段。**左右の余白は帯ではなく各段が持つ**（帯に持たせると、横
/// スクロールの器がその内側で切れ、画面の端より手前でチップが途切れる。web と同じ）。
class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        for (final (i, child) in children.indexed) ...[
          // web の `gap-1`（カテゴリ）/ `gap-1.5`（タグ）の間を取った値
          if (i > 0) const SizedBox(width: 5),
          child,
        ],
      ],
    ),
  );
}

/// 上の段のチップ（「すべて」とカテゴリ）。**見た目と選び方はカレンダーの
/// フィルタと同じ**（web の `CoCalendarControls` / `CoArticleFilter`）。
///
/// - 選ばれていない … 枠と副テキスト。カテゴリは色の点を 30% で添える（凡例を兼ねる）
/// - 選ばれた「すべて」… 主テキストと地（`bg`）
/// - 選ばれたカテゴリ … 文字がカテゴリの色、地はその 6%、枠は 35%、点は 100%
class FilterChipButton extends StatelessWidget {
  const FilterChipButton.all({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  }) : slug = null;

  const FilterChipButton.category({
    required this.label,
    required String this.slug,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String? slug;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final slug = this.slug;
    final line = slug == null ? null : CategoryPalette.lineOf(slug, colors);

    final Color fg;
    final Color? bg;
    final Color borderColor;
    if (!selected) {
      fg = colors.textSub;
      bg = null;
      borderColor = colors.border;
    } else if (line == null) {
      fg = colors.text;
      bg = colors.bg;
      borderColor = colors.border;
    } else {
      fg = line;
      bg = line.withValues(alpha: 0.06);
      borderColor = line.withValues(alpha: 0.35);
    }

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: bg ?? Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: borderColor)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            // web の `px-2.5 py-1.5`（カテゴリは `px-2`）
            padding: EdgeInsets.symmetric(
              horizontal: slug == null ? 10 : 8,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (line != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: line.withValues(alpha: selected ? 1 : 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(fontSize: 13, height: 1, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 下の段のタグ。**複数選べる。** 選ばれたら反転（地が主テキスト、文字が面色）。
class TagToggleChip extends StatelessWidget {
  const TagToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      toggled: selected,
      button: true,
      child: Material(
        // web の `bg-brand-text/8` と、選択中の `bg-brand-text`
        color: selected ? colors.text : colors.text.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            // web の `px-2 py-1`
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: selected ? colors.surface : colors.textSub,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
