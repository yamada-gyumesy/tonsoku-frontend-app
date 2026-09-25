import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/analytics/screen_path.dart';
import 'package:tonsoku/core/analytics/track_screen.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/lifecycle/app_resume.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/home/presentation/header_hide_controller.dart';
import 'package:tonsoku/features/home/presentation/widgets/article_card.dart';
import 'package:tonsoku/features/home/presentation/widgets/article_card_skeleton.dart';
import 'package:tonsoku/features/home/presentation/widgets/deal_coupon_section.dart';
import 'package:tonsoku/features/home/presentation/widgets/limited_weeks_section.dart';
import 'package:tonsoku/features/shell/presentation/widgets/tonsoku_app_bar.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/widgets/async_list_view.dart';
import 'package:tonsoku/shared/widgets/section_heading.dart';

/// ホームタブ。**web の TOP（`src/pages/[...locale]/index.astro`）と同じ構成。**
///
/// 店舗限定（週カード）→ お得なクーポン → 最新記事 10 件 →「過去の記事を見る」。
///
/// ## gyumesy-frontend-app のホームを写さなかった理由
///
/// **あちらはカテゴリのタブ列とおすすめメニューを持つが、とん速の TOP は
/// どちらも外している**（web #131。ユーザーの判断）。ギュメシーの計測で
/// タブがほとんど使われておらず、記事への入口はほぼ検索なので、TOP は常連が
/// 遊ぶ場所として店舗限定を主役にした。**「gyumesy と同じにする」を理由に
/// タブを戻さないこと**（web の CLAUDE.md）。
///
/// 記事を絞りたい人は「過去の記事を見る」の先（[onOpenArchive]）のフィルタで絞る。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    required this.onOpenArticle,
    required this.onOpenArchive,
    required this.onOpenCoupon,
    super.key,
  });

  final ValueChanged<String> onOpenArticle;

  /// 「過去の記事を見る」。記事一覧（web の `/articles/`）を開く。
  final VoidCallback onOpenArchive;

  /// クーポンタブへ移る（「お得なクーポン」の「クーポン一覧」）。
  final VoidCallback onOpenCoupon;

  /// TOP に置く最新記事の件数（web の `LATEST_COUNT`）。**続きは
  /// 「過去の記事を見る」で明示的に辿らせる**（無限スクロールをやめた。
  /// web のユーザー設計）。
  static const latestCount = 10;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// ロゴバーの退避量。判定は [HeaderHideController]（gyumesy と同じ）。
  final _headerHidden = HeaderHideController(maxHidden: TonsokuAppBar.height);

  /// アクティブ復帰で取り直している最中か。**二重に走らせないためだけ**に持つ
  /// （骨組みは重ねない。gyumesy が「開くたびに骨組みが出て消える」を実機で
  /// 指摘されて撤去している）。
  bool _reloading = false;

  @override
  void dispose() {
    _headerHidden.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_reloading) return;
    _reloading = true;
    // **`await` の前に容れ物を捕まえる**（`pullToRefresh` の doc と同じ理由。
    // 取り直しの間に画面が外れても安全に貼り直せる）
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await refreshHomeLists(container);
    } finally {
      _reloading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // **アプリがアクティブになったら取り直す。** 速報性が売りなので、開き直した
    // 時に最新が出ていないと成り立たない（gyumesy と同じ）
    listenAppResume(ref, _reload);

    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final topInset = MediaQuery.paddingOf(context).top + TonsokuAppBar.height;

    final feed = ref.watch(feedProvider);
    // **カテゴリは空に潰してよい**（ホームはカテゴリで絞らない。チップが
    // 出ないだけで記事は選べる。絞り込みの土台にしている記事一覧は別の扱い）
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    // **タグだけは空に潰してよい。** 記事カードのタグは補助情報で、無くても
    // タイトル・日付・カテゴリで記事は選べる（gyumesy と同じ）
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    // **店舗限定は取れなければ節ごと出さない。** 主役の節だが、無くても
    // 記事は読める（web も 1 枚も無ければ節ごと出さない）
    final weeks = ref.watch(limitedWeeksProvider).value?.weeks ?? const [];

    return TrackScreen(
      screen: ScreenPath.home(
        ref.watch(localeControllerProvider),
        ref.watch(messagesProvider),
      ),
      child: Scaffold(
        backgroundColor: colors.page,
        body: NotificationListener<ScrollUpdateNotification>(
          onNotification: _headerHidden.handleScroll,
          child: Stack(
            children: [
              RefreshIndicator(
                // 引っ張って更新の輪はヘッダーの下から出す
                edgeOffset: topInset,
                onRefresh: _reload,
                child: CustomScrollView(
                  // 中身が短くても引っ張って更新できるようにする
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ヘッダーに潜り込ませるぶんの余白 ＋ web の `pt-4`
                    SliverToBoxAdapter(child: SizedBox(height: topInset + 16)),
                    SliverToBoxAdapter(
                      child: LimitedWeeksSection(
                        weeks: weeks,
                        onOpenArticle: widget.onOpenArticle,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: DealCouponSection(
                        onOpenArticle: widget.onOpenArticle,
                        onOpenCoupon: widget.onOpenCoupon,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SectionHeading(label: t.homeLatestHeading),
                      ),
                    ),
                    ..._latest(
                      feed: feed,
                      categories: categories,
                      tags: tags,
                      noArticles: t.commonNoArticles,
                      pastArticles: t.homePastArticles,
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: _headerHidden,
                builder: (context, hidden, _) => Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: TonsokuAppBar(hidden: hidden),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _latest({
    required AsyncValue<List<ArticleMeta>> feed,
    required List<Category> categories,
    required List<Tag> tags,
    required String noArticles,
    required String pastArticles,
  }) {
    // **失敗を「空」に潰さない。** 前回の値がある間は出したまま差し替え、
    // エラー画面を出すのは前回値の無い初回取得の失敗だけにする（gyumesy と同じ）
    final items = feed.value;
    if (items == null) {
      return [
        if (feed.hasError)
          SliverToBoxAdapter(child: LoadFailure(onRetry: _reload))
        else
          // 初回取得は骨組みを見せる（空回りのスピナーより、これから何が
          // 並ぶかが分かる）
          const SliverToBoxAdapter(child: ArticleCardSkeleton()),
      ];
    }
    if (items.isEmpty) {
      return [SliverToBoxAdapter(child: EmptyHint(message: noArticles))];
    }

    final latest = items.take(HomePage.latestCount).toList(growable: false);
    return [
      SliverList.builder(
        itemCount: latest.length,
        itemBuilder: (context, i) => ArticleCard(
          article: latest[i],
          categories: categories,
          tags: tags,
          onTap: () => widget.onOpenArticle(latest[i].slug),
        ),
      ),
      if (items.length > HomePage.latestCount)
        SliverToBoxAdapter(
          child: Padding(
            // web の `px-4 py-6`
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: _PastArticlesButton(
              label: pastArticles,
              onTap: widget.onOpenArchive,
            ),
          ),
        ),
    ];
  }
}

/// 「過去の記事を見る」。web の `rounded-full border bg-brand-surface py-3
/// font-bold text-sm`。
class _PastArticlesButton extends StatelessWidget {
  const _PastArticlesButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: StadiumBorder(side: BorderSide(color: colors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        highlightColor: colors.hover,
        splashColor: colors.hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
