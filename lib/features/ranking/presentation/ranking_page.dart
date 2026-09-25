import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/article/presentation/widgets/back_to_list.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/home/data/article_repository.dart';
import 'package:tonsoku/features/home/presentation/widgets/article_card.dart';
import 'package:tonsoku/features/home/presentation/widgets/article_card_skeleton.dart';
import 'package:tonsoku/features/ranking/data/ranking_repository.dart';
import 'package:tonsoku/features/ranking/domain/ranking_entries.dart';
import 'package:tonsoku/features/ranking/presentation/widgets/ranking_card.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/ranking.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/utils/pull_to_refresh.dart';
import 'package:tonsoku/shared/widgets/async_list_view.dart';
import 'package:tonsoku/shared/widgets/back_header.dart';
import 'package:tonsoku/shared/widgets/sticky_band.dart';

/// ランキング。web の `/ranking/`（gyumesy-frontend-app の `RankingPage` を写し、
/// とん速の作りに合わせ直した）。デイリー / ウィークリー / マンスリーの 3 つ。
///
/// **配信されるのは順位と slug だけ**なので、記事メタは一覧側と突き合わせて描く
/// （`rankingWindowsProvider`）。
///
/// ## gyumesy との違い
///
/// - **メニューから開く画面**（gyumesy は下タブ）。見出しの上に戻るの帯を置く
/// - **期間タブは記事一覧の絞り込みと同じ帯で貼り付ける**（`StickyBand`。web の
///   `.sticky-band`）。gyumesy は浮いたカードの `StickyToolbar`
/// - **窓を横に並べない**（`PageView` を使わない）。1 本の一覧で選んだ窓だけを描き、
///   左右に払うと隣の窓へ送る（web の `data-ranking-swipe` と同じ動き）。web も
///   3 つの窓で縦のスクロール位置を共有している
class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({required this.onOpenArticle, super.key});

  final ValueChanged<String> onOpenArticle;

  /// 払ったと見なす速さ（px/s）。これ未満は縦のスクロールの揺れとして捨てる。
  static const swipeVelocity = 300.0;

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  /// 利用者が選んだ窓。**選ぶまでは null。**
  ///
  /// **「選んでいない」を null で表す**（gyumesy と同じ）。最初の 1 回だけコードが
  /// 入れる形にすると、そのあと中身が変わっても追随できない —— デイリーは 04:00 に
  /// 切り替わるので、前日ぶんのキャッシュ（デイリー 5 件）で確定した直後に通信の
  /// 結果（デイリー 0 件）が来ると、空の窓を見せたまま止まる。
  RankingWindow? _chosen;

  /// 帯が貼り付いたか（番兵で判定する。記事一覧と同じ）。
  final _stuck = ValueNotifier(false);
  final _sentinel = GlobalKey();
  final _viewport = GlobalKey();

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

  /// 引っ張って更新。**集計は日次で更新される**ので、開き直さずに取り直せる必要が
  /// ある。
  ///
  /// **一覧（`index.json`）も一緒に取り直す。** 画面が見ているのは順位と一覧の
  /// 突き合わせで、一覧に無い slug は捨てる作り。順位だけ新しくすると、新しく
  /// 入った記事が順位ごと消える（gyumesy の実測）。**温めた後に貼り直す**
  /// （理由は [pullToRefresh]）。
  Future<void> _reload() => pullToRefresh(
    context,
    warm: (c) => Future.wait<void>([
      c.read(rankingRepositoryProvider).refreshRanking(),
      c.read(articleRepositoryProvider).refreshArticleIndex(),
    ]),
    reattach: (c) => c
      ..invalidate(rankingProvider)
      ..invalidate(articleIndexProvider),
  );

  /// 左右に払った。**端では止める**（回り込ませない。web と同じ）。
  void _swipe(DragEndDetails details, RankingWindow current) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < RankingPage.swipeVelocity) return;
    final index =
        RankingWindow.values.indexOf(current) + (velocity < 0 ? 1 : -1);
    if (index < 0 || index >= RankingWindow.values.length) return;
    setState(() => _chosen = RankingWindow.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final windows = ref.watch(rankingWindowsProvider);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final resolved = windows.value;
    // 選ぶまでは中身のある最初の窓に追随する
    final selected =
        _chosen ??
        (resolved == null ? RankingWindow.daily : initialWindow(resolved));

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
                child: GestureDetector(
                  onHorizontalDragEnd: resolved == null
                      ? null
                      : (details) => _swipe(details, selected),
                  child: CustomScrollView(
                    key: _viewport,
                    // 中身が短くても引っ張って更新できるようにする
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: RankingHeader(
                          updatedAt:
                              ref.watch(rankingProvider).value?.computedAt ??
                              '',
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(key: _sentinel)),
                      StickyBand(
                        stuck: _stuck,
                        child: RankingTabs(
                          selected: selected,
                          stuck: _stuck,
                          onSelect: (window) =>
                              setState(() => _chosen = window),
                        ),
                      ),
                      ..._body(
                        windows: windows,
                        entries: resolved?[selected],
                        categories: categories,
                        tags: tags,
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
          ),
        ],
      ),
    );
  }

  List<Widget> _body({
    required AsyncValue<Map<RankingWindow, List<RankingEntry>>> windows,
    required List<RankingEntry>? entries,
    required List<Category> categories,
    required List<Tag> tags,
  }) {
    // **取れなかったことを「ランキングが無い」に化けさせない。** 再試行できる形で
    // 出す。`index.json` は大きく、`ranking.json` より遅れて届く。その間に空を
    // 出さない（`rankingWindowsProvider` が両方揃うまで loading を返す）
    if (entries == null) {
      return [
        if (windows.hasError)
          SliverToBoxAdapter(child: LoadFailure(onRetry: _reload))
        else
          const SliverToBoxAdapter(child: ArticleCardSkeleton()),
      ];
    }
    if (entries.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyHint(message: ref.watch(messagesProvider).rankingEmpty),
        ),
      ];
    }
    // **上位は「順位が [rankingTopRank] 以内か」で分ける。** 件数で切ると、一覧に
    // 無い slug が落ちた時に 4 位が大きいカードに繰り上がって、順位と見た目が
    // 食い違う
    return [
      SliverList.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          if (isTopRank(entry.rank)) {
            return RankingCard(
              rank: entry.rank,
              article: entry.article,
              categories: categories,
              tags: tags,
              onTap: () => widget.onOpenArticle(entry.article.slug),
            );
          }
          // 4 位以下は一覧と同じカードに順位バッジを載せたもの。区切り線と
          // 余白が上位と共通なので、順位の連なりとして続けて読める。
          // **`compact` は必須**（外すと見出しが上位 3 件と同じ大きさになる）
          return ArticleCard(
            article: entry.article,
            categories: categories,
            tags: tags,
            rank: entry.rank,
            compact: true,
            onTap: () => widget.onOpenArticle(entry.article.slug),
          );
        },
      ),
    ];
  }
}

/// 集計期間のタブ。web の `CoRankingTabs`。
///
/// **選択中は「文字を本文色に戻す＋下線」だけで示す。** 塗り潰すと貼り付いた帯の
/// 中で色の塊がページの主役より目立つ（web の注記）。下線は `primaryText`
/// （web の `--color-brand-primary-text`。gyumesy はセカンダリーの青）。
///
/// **下線はラベルの幅ぶんだけ。** タブ幅いっぱいに伸ばすと、3 本の帯を塗り
/// 分けたように見える（web も明示的に禁じている）。
class RankingTabs extends ConsumerWidget {
  const RankingTabs({
    required this.selected,
    required this.stuck,
    required this.onSelect,
    super.key,
  });

  final RankingWindow selected;

  /// 貼り付いたか。**貼り付いたらタブの下端の区切り線を消す**（帯の線 ―― 紙面の
  /// 端から端まで ―― がその役を引き受ける。web のユーザー指定）。
  final ValueNotifier<bool> stuck;

  final ValueChanged<RankingWindow> onSelect;

  /// ラベルの上下の余白。web の span の `py-4`。
  static const labelPadding = 16.0;

  /// 選択中の下線。web の `height: 3px` + `border-radius: 9999px`。
  static const underlineHeight = 3.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    final labels = {
      RankingWindow.daily: t.rankingDaily,
      RankingWindow.weekly: t.rankingWeekly,
      RankingWindow.monthly: t.rankingMonthly,
    };

    return Padding(
      // web の帯の `px-4`。**タブの下端の線はこの内側に引く**（下の記事カードの
      // 線と同じ幅になる。web のユーザー指定）
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        label: t.rankingTabGroup,
        container: true,
        child: ValueListenableBuilder<bool>(
          valueListenable: stuck,
          builder: (context, isStuck, child) => DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  // 透明で残すのは、消し引きすると高さが 1px 動いて中身が跳ねるため
                  color: isStuck ? Colors.transparent : colors.border,
                ),
              ),
            ),
            child: child,
          ),
          child: Row(
            children: [
              for (final window in RankingWindow.values)
                // 本文カラムを 3 等分する（指で押せる幅を確保する）
                Expanded(
                  child: Semantics(
                    selected: window == selected,
                    inMutuallyExclusiveGroup: true,
                    button: true,
                    child: GestureDetector(
                      onTap: () => onSelect(window),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        // ラベルの幅にだけ広がる箱。下線もこの幅になる
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: labelPadding,
                              ),
                              child: Text(
                                labels[window]!,
                                textAlign: TextAlign.center,
                                // **折り返させない。** 1 つだけ 2 行になると、
                                // 他の下線が区切り線から浮く
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1,
                                  // **太字は選択中でも未選択でも変えない。**
                                  // 切替のたびに文字幅が動いてタブの位置がずれる
                                  fontWeight: FontWeight.bold,
                                  color: window == selected
                                      ? colors.text
                                      : colors.textSub,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: underlineHeight,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  // **未選択でも場所ごと残す**（web は
                                  // `opacity: 0`）。出し入れすると切替のたびに
                                  // 幅が動いて点滅して見える
                                  color: window == selected
                                      ? colors.primaryText
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 見出しと更新日。web の `ranking.astro` の h1 行。
///
/// **端末の文字サイズを上げても壊さない。** 同じ行に並べるだけだと、更新日が
/// 見出しを押し潰す（gyumesy の実測で 320pt の x1.5 から見出しが 1 文字ずつ
/// 折り返し、x2.0 で幅 0 になって消えた）。**入り切らなければ更新日を次の行へ
/// 送る。**
///
/// テストから直接組めるよう公開している（この壊れ方は画面ごと組まないと
/// 確かめられない）。
class RankingHeader extends ConsumerWidget {
  const RankingHeader({required this.updatedAt, super.key});

  /// `computed_at`。空なら出さない。
  final String updatedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    final parsed = DateTime.tryParse(updatedAt);

    return Padding(
      // web の `pt-4`（16）。下の 8 は h1 行の `mb-2`。**他ページの `mb-6` より
      // 詰めてある**（web の注記: すぐ下のタブが区切り線で終わる作りなので、
      // 見出し〜タブ文字（24 ＝ この 8 ＋ タブの py-4 の 16）と区切り線〜1件目
      // （16）がちょうど 1.5 倍に収まる）
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        width: double.infinity,
        // web の h1 行の `pb-2 border-b-2 border-brand-primary-text`
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.primaryText, width: 2),
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          runSpacing: 4,
          children: [
            Semantics(
              header: true,
              child: Text(
                t.rankingPageTitle,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ),
            if (parsed != null)
              Text(
                t.rankingUpdatedAt(
                  formatDateOnly(parsed, ref.watch(localeControllerProvider)),
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSub,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
