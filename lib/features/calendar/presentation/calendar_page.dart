import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/article/presentation/widgets/back_to_list.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/calendar/domain/calendar_grid.dart';
import 'package:tonsoku/features/calendar/domain/calendar_window.dart';
import 'package:tonsoku/features/calendar/domain/day_lanes.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/calendar_day_row.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/day_events_sheet.dart';
import 'package:tonsoku/features/calendar/presentation/widgets/month_grid.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/home/data/article_repository.dart';
import 'package:tonsoku/features/home/presentation/article_list_page.dart';
import 'package:tonsoku/features/home/presentation/header_hide_controller.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/models/tag.dart';
import 'package:tonsoku/shared/utils/pull_to_refresh.dart';
import 'package:tonsoku/shared/widgets/async_list_view.dart';
import 'package:tonsoku/shared/widgets/back_header.dart';

/// カレンダー。web の `/calendar/`（gyumesy-frontend-app の `CalendarPage` を写し、
/// とん速の作りに合わせ直した）。松のやの予定を月表示する。
///
/// 上から、見出し → 月ナビとカテゴリ（貼り付く帯）→ 月グリッド → 月の全日の
/// 日リスト。web の `calendar.astro` と同じ並び。
///
/// ## gyumesy との違い
///
/// - **メニューから開く画面**（gyumesy は下タブ）。見出しの上に「＜ 戻る」の帯を
///   置き、**スクロールで退かせる**（ランキングと同じ。`HeaderHideController`）
/// - **月ナビとカテゴリはヘッダーのすぐ下に貼り付ける**（web の `.sticky-band`。
///   枠・影なし、貼り付いたら紙面の端から端まで線）。gyumesy は浮いたカードの
///   `StickyToolbar`（`NestedScrollView`）。**貼り付け方はランキングの期間タブと
///   同じ**（一覧の中の帯はそのまま流し、ヘッダーの裏まで来たら同じ帯を上に重ねる）
/// - **表示状態を URL に写さない**（gyumesy の `_syncUrl` / `didUpdateWidget` を
///   持ってこない）。あちらはカレンダーがタブで、**同じ State に導線から何度も
///   値が届く**ので URL と画面を揃え続ける必要があった。とん速では**開くたびに
///   画面を積む**ので、導線の値は `initState` で 1 度読めば足りる
/// - **月の指定（`initialMonth`）を持たない。** 渡す導線（記事詳細の「最近の予定」）が
///   まだ無い。入れる時は gyumesy の `initialMonth` と web の `#month=` を見ること
/// - **月の範囲に下限と上限がある**（`calendarMonthRange`。web と同じ）。最初に出す
///   月は範囲の端へ寄せる（gyumesy は範囲外なら今月）
/// - **記事が無くなった予定はリンクにしない**（`calendarEventsProvider`）
/// - **花吹雪（`celebrate`）を持ってこない。** 松屋の創業記念日の予定
///   （`anniversary-` の id）を押した時だけ鳴る演出で、**とん速の配信はその予定を
///   出さない**（`tonsoku-backend-batch` に取り込みが無い。本番の 23 件にも無い）。
///   web には `calendar-celebrate.ts` が写してあるが、鳴る経路が無い。配信が
///   松のやの記念日を出すようになったら、gyumesy の `celebrate.dart` と
///   `isAnniversary` を写すこと
/// - **画面の計測（`TrackScreen`）を持たない**（GA4 は後の Issue）
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({
    required this.onOpenArticle,
    this.initialCategory,
    super.key,
  });

  final ValueChanged<String> onOpenArticle;

  /// 開いた時に絞るカテゴリ（slug）。**null なら「すべて」。**
  ///
  /// **クーポンの「カレンダーをみる」が `campaign` を渡す**（web は
  /// `/calendar/#category=campaign`）。ルートは `?category=` で受ける
  /// （`calendarRoute`）。web がハッシュを使うのは、クエリだと別 URL として
  /// クロールされるからで、アプリにはその問題が無い。
  ///
  /// **配信に無いカテゴリは「すべて」に落とす**（web も
  /// `allCats.includes(urlCategory) ? .. : null`。外から URL で来る経路は何でも
  /// 書ける）。
  final String? initialCategory;

  /// 月を送る最小の移動量。web の `MIN_PX`。
  static const swipeMinPx = 80.0;

  /// 最小の速さ。web の `MIN_VELOCITY`（0.8px/ms）。
  ///
  /// **払い全体の平均で見る**（`|dx| / 経過ms`）。web の `swipe.ts` もそう
  /// 測っている。離した瞬間の速度（`primaryVelocity`）で見ると、勢いよく
  /// 始めて指を止めて離した払いが落ち、逆にゆっくり動かして最後だけ弾いた
  /// 払いが通る（gyumesy の注記）。
  static const swipeMinVelocity = 0.8;

  /// 本文の左右の余白（web の `main` の `px-4`）。
  static const pageInset = 16.0;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  /// 利用者が選んだ月（`YYYY-MM`）。**選ぶまでは null。**
  ///
  /// **「選んでいない」を null で表す**（ランキングの窓と同じ）。最初に出す月は
  /// 配信の範囲で決まる（`initialCalendarMonth`）が、`initState` の時点では
  /// まだ配信が届いていない。届く前に今月で確定させると、下限が今月より先に
  /// ある時に範囲外の月を出したまま止まる。
  String? _chosenMonth;

  /// 線を引くカテゴリ。**null が「すべて」で、その時は線を出さない。**
  late String? _lineMode = widget.initialCategory;

  /// カテゴリの中をさらに絞るタグ（複数選べる）。
  ///
  /// **カテゴリを選んでいる時だけ出す。** 「すべて」の時に出すと、どの
  /// カテゴリのタグなのか分からない。
  /// **書き換えず、毎回作り直す**（gyumesy の注記: 同じ `Set` を書き換えると
  /// 変化として検知できない）。
  var _childTags = const <String>{};

  /// いま開いているマークの予定 id。**空でない間、他のマークが薄くなる**
  /// （web の `gy-cal-dim`）。
  ///
  /// **日付のマスを押した時は入れない。** web も日クリックでは薄くしない。
  var _activeEventIds = const <String>{};

  /// 薄くする範囲。**押したビューの中だけ**（web の `applyHighlight` は
  /// `closest('[data-grid], [data-calendar-list]')` で押した側だけを落とす）。
  bool _activeInGrid = true;

  /// いま開いている日。**月グリッドのマスと日リストの行を両方光らせる**
  /// （web の `bindDaySelect.highlightDay`）。
  ///
  /// **マークを押した時は入れない。** web も `bindMarks` では日を光らせない。
  String? _selectedDate;

  /// 払っている間の横移動と、その始まり／終わりの時刻。
  double _dragX = 0;
  Duration _dragStart = Duration.zero;
  Duration _dragEnd = Duration.zero;

  /// 今日の行。「今日」を押した時にここまで運ぶ。
  final _todayKey = GlobalKey();

  /// 「＜ 戻る」の帯の退避量（ランキングと同じ。スクロールに 1:1 で追従する）。
  final _headerHidden = HeaderHideController(maxHidden: BackHeader.height);

  /// 月ナビとカテゴリの帯が見出しの帯の裏まで来たか（番兵で判定する）。
  final _stuck = ValueNotifier(false);
  final _sentinel = GlobalKey();
  final _stack = GlobalKey();

  @override
  void dispose() {
    _headerHidden.dispose();
    _stuck.dispose();
    super.dispose();
  }

  /// ヘッダーの下端（状態バー＋ヘッダーの見えているぶん）。
  double get _headerBottom =>
      MediaQuery.paddingOf(context).top +
      BackHeader.height -
      _headerHidden.value;

  bool _onScroll(ScrollUpdateNotification notification) {
    _headerHidden.handleScroll(notification);
    _updateStuck();
    // **並べ直した後にもう一度測る。** 通知はスクロール位置が変わった直後・
    // 並べ直す前に届くので、ここで測る番兵の位置は 1 つ前のフレームのもの。
    // 最後の通知でずれたままになると、先頭まで戻したのに貼り付いた帯が
    // 残る（テストで踏んだ。ランキングにも同じずれがある）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateStuck();
    });
    return false;
  }

  void _updateStuck() {
    final sentinel = _sentinel.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    if (sentinel == null || stack == null || !sentinel.attached) return;
    final y = sentinel.localToGlobal(Offset.zero, ancestor: stack).dy;
    _stuck.value = y <= _headerBottom;
  }

  /// 引っ張って更新。**記事の一覧も一緒に取り直す**（予定のリンクを実在する
  /// 記事に絞っているので、予定だけ新しくすると、新しく入った記事の予定が
  /// リンクにならない。ランキングと同じ理由）。**温めた後に貼り直す**
  /// （理由は [pullToRefresh]）。
  Future<void> _reload() => pullToRefresh(
    context,
    warm: (c) => Future.wait<void>([
      c.read(calendarRepositoryProvider).refreshCalendar(),
      c.read(articleRepositoryProvider).refreshArticleIndex(),
    ]),
    reattach: (c) => c
      ..invalidate(calendarProvider)
      ..invalidate(articleIndexProvider),
  );

  /// 見ているもの（月・カテゴリ・タグ）を変える。**強調も一緒に落とす。**
  ///
  /// web は月送り・カテゴリ切替・タグ切替のたびに `popover.hide()` を呼び、
  /// 日の色とマークの強調を消している。残すと、**別の月を見ているのに前の月で
  /// 押した日が光ったまま**になる（gyumesy の `_Calendar.didUpdateWidget`）。
  void _changeView(VoidCallback change) => setState(() {
    change();
    _selectedDate = null;
    _activeEventIds = const {};
  });

  /// 配信データに実在するカテゴリだけ。**知らないスラッグは「すべて」。**
  ///
  /// **読み込み中は判定しない。** 配信が届くまで `categories` は空なので、
  /// そこで潰すと絞り込みが一瞬「すべて」に見えてから戻る（gyumesy の注記）。
  String? _effectiveLineMode(List<Category> categories) =>
      categories.isEmpty || categories.any((c) => c.slug == _lineMode)
      ? _lineMode
      : null;

  void _shiftMonth(int delta, String month, ({String min, String max}) range) {
    final shifted = addMonths(month, delta);
    if (shifted.compareTo(range.min) < 0 || shifted.compareTo(range.max) > 0) {
      return;
    }
    _changeView(() => _chosenMonth = shifted);
  }

  /// 「今日」を押した。
  ///
  /// **当月を表示中でも必ず動かす。** 何も起きないと押したことが伝わらない
  /// （web も同じ理由で毎回スクロールさせる）。**今日を光らせ**（web の
  /// `highlightDay(buildToday)`）、**日リストの当日の行まで運ぶ**（web の
  /// `scrollIntoView({block:'center'})`）。
  ///
  /// **そのために日リストは一括で組んでいる**（遅延生成だと画面外の行が存在せず
  /// `ensureVisible` が効かない。gyumesy が実機で踏んだ）。
  ///
  /// 今月が範囲の外（下限より前）にある時は範囲の端へ寄せる。その月に今日の
  /// 行は無いので、運ぶ先も無い。
  void _goToToday(String today, ({String min, String max}) range) {
    _changeView(() {
      _chosenMonth = initialCalendarMonth(range, today);
    });
    setState(() => _selectedDate = today);

    // 月を切り替えた直後は行がまだ組み直されていないので、次のフレームで運ぶ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _todayKey.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        // web の `block: 'center'`
        alignment: 0.5,
      );
    });
  }

  /// 絞り込みを適用した予定。
  ///
  /// **見せる所すべてがここを通る**（月グリッド・日リスト・日付シート）。
  /// gyumesy が 3 通りに書いていた時は、**グリッドとシートがタグを見ておらず**、
  /// タグを押しても日リストしか変わらなかった。
  ///
  /// **タグを 1 つでも押したら、対象タグを持たない予定は落ちる。** 全部押しても
  /// 未選択と同じにはならない（web と同じ。「期間限定」を押した人が見たいのは
  /// 期間限定だけ）。
  List<CalendarEvent> _filtered(List<CalendarEvent> events, String? lineMode) {
    final byCategory = lineMode == null
        ? events
        : events.where((e) => e.category == lineMode).toList();
    if (lineMode == null || _childTags.isEmpty) return byCategory;
    return byCategory.where((e) => e.tags.any(_childTags.contains)).toList();
  }

  /// そのカテゴリの予定に実際にあるタグだけ、**配信の `tags.json` の順**で返す
  /// （web の `CoCalendarControls`。こちらで並べ直すと配信が意図した順が消える）。
  ///
  /// **押しても 1 件も残らないチップを並べない。** 絞り込みが壊れているように
  /// 見える。
  List<Tag> _childTagsOf(
    List<CalendarEvent> events,
    List<Tag> tags,
    String category,
  ) {
    final present = {
      for (final e in events)
        if (e.category == category) ...e.tags,
    };
    return tags.where((t) => present.contains(t.slug)).toList();
  }

  /// 押された予定を出す。**1 件でも複数でも同じ入口**（同じ期間の予定は 1 本の
  /// 線を共有しているので、押した先で選ばせる）。
  ///
  /// `date` は**押されたマスの日**。線の代表の開始日ではない。
  Future<void> _openEvents(
    String date,
    List<CalendarEvent> events,
    _SheetContext sheet, {

    /// 押されたのが月グリッドか（false なら日リスト）。**薄くする範囲を決める。**
    bool fromGrid = true,
  }) async {
    if (events.isEmpty) return;

    // **押したマークだけ残して他を薄くする**（web の `applyHighlight`）。
    // 線は何本も重なるので、どれを開いたのかが色だけでは分からない
    setState(() {
      _activeEventIds = {for (final e in events) e.id};
      _activeInGrid = fromGrid;
      // **日の強調は落とす。** web も `popover.onRender` で消している
      _selectedDate = null;
    });
    try {
      // **1 件でも記事へ直行しない。** web は線・丸ポチ・`+N` のどれを押しても
      // ポップオーバーを出すだけで、記事へは中の題を押して初めて飛ぶ。
      // 直行させると、**同じ線でも束ねている件数によって行き先が変わる**
      // （gyumesy の注記）
      await _openDay(date, sheet, only: events);
    } finally {
      // **閉じたら必ず戻す。** 記事へ遷移した時も、戻ってきた画面が薄いままに
      // ならないようにする
      if (mounted) setState(() => _activeEventIds = const {});
    }
  }

  Future<void> _openDay(
    String date,
    _SheetContext sheet, {
    List<CalendarEvent>? only,
  }) {
    // **マークからの時は日を光らせない**（web の `bindMarks` は
    // `highlightDay` を呼ばない）。日のマス・日リストの行から来た時だけ塗る
    if (only == null) setState(() => _selectedDate = date);

    return showDayEventsSheet(
      context,
      date: date,
      today: sheet.today,
      // **絞り込み中はシートも絞る。** 店舗で絞っているのにメニューが並ぶと、
      // 絞り込みが効いていないように見える（web も明示的に絞り、0 件なら開かない）
      events: only ?? sheet.shown,
      categories: sheet.categories,
      tags: sheet.tags,
      onOpenArticle: widget.onOpenArticle,
    ).whenComplete(() {
      // **閉じたら解除する**（web は `popover.onHide` で消している）
      if (mounted && only == null) setState(() => _selectedDate = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final events = ref.watch(calendarEventsProvider);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final tags = ref.watch(tagsProvider).value ?? const <Tag>[];
    final topInset = MediaQuery.paddingOf(context).top + BackHeader.height;

    final data = events.value;
    final today = todayInJst();
    final range = data == null ? null : calendarMonthRange(data, today);
    final month = range == null
        ? null
        : _clampMonth(
            _chosenMonth ?? initialCalendarMonth(range, today),
            range,
          );
    final lineMode = _effectiveLineMode(categories);

    Widget? toolbar() => data == null || range == null || month == null
        ? null
        : CalendarToolbar(
            month: month,
            range: range,
            onShift: (delta) => _shiftMonth(delta, month, range),
            onToday: () => _goToToday(today, range),
            categories: categories,
            lineMode: lineMode,
            onSelectLineMode: (mode) => _changeView(() {
              _lineMode = mode;
              // カテゴリを変えたらタグの絞り込みは捨てる（別のカテゴリに
              // 無いタグが残ると 1 件も出なくなる）
              _childTags = const {};
            }),
            childTags: lineMode == null
                ? const []
                : _childTagsOf(data, tags, lineMode),
            selectedChildTags: _childTags,
            onToggleChildTag: (tag) => _changeView(() {
              _childTags = _childTags.contains(tag)
                  ? _childTags.where((t) => t != tag).toSet()
                  : {..._childTags, tag};
            }),
          );

    return Scaffold(
      backgroundColor: colors.page,
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: _onScroll,
        child: Stack(
          key: _stack,
          children: [
            RefreshIndicator(
              // 引っ張って更新の輪はヘッダーの下から出す
              edgeOffset: topInset,
              onRefresh: _reload,
              child: CustomScrollView(
                // 中身が短くても引っ張って更新できるようにする
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // **ヘッダーぶんの余白はスクロールする側が持つ**（ランキングと
                  // 同じ。外に置くと、ヘッダーが退いた時に空の帯として残る）
                  SliverToBoxAdapter(child: SizedBox(height: topInset)),
                  const SliverToBoxAdapter(child: CalendarHeader()),
                  SliverToBoxAdapter(child: SizedBox(key: _sentinel)),
                  if (toolbar() case final bar?) SliverToBoxAdapter(child: bar),
                  ..._body(
                    events: events,
                    today: today,
                    month: month,
                    range: range,
                    lineMode: lineMode,
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
            // **貼り付いた帯は、ヘッダーのすぐ下に重ねて出す**（ランキングの
            // 期間タブと同じ作り。スクロールの中で `pinned` にすると、貼り付く先が
            // 画面の上端＝ヘッダーの裏になって隠れる）。**一覧の中の帯はそのまま
            // 流し**、見出しの帯の裏まで来たら同じ帯をこちらに出す。
            //
            // 同じ帯を 2 つ組むので、**カテゴリの行を横に送った位置だけは
            // 2 つで別々**になる（貼り付いた側で送っても、戻った時の一覧の中の
            // 帯は元の位置）。選んでいるものは同じ State から描くので食い違わない
            AnimatedBuilder(
              animation: Listenable.merge([_headerHidden, _stuck]),
              builder: (context, _) => switch ((_stuck.value, toolbar())) {
                (true, final bar?) => Positioned(
                  top: _headerBottom,
                  left: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      // **貼り付いた時の線は紙面の端から端まで**（web の
                      // `.sticky-band`）。外側に描いて高さを変えない
                      boxShadow: [
                        BoxShadow(
                          color: colors.border,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: bar,
                  ),
                ),
                _ => const SizedBox.shrink(),
              },
            ),
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

  /// 範囲の外に出ていたら端へ寄せる（配信が更新されて範囲が縮んだ時）。
  static String _clampMonth(String month, ({String min, String max}) range) {
    if (month.compareTo(range.min) < 0) return range.min;
    if (month.compareTo(range.max) > 0) return range.max;
    return month;
  }

  List<Widget> _body({
    required AsyncValue<List<CalendarEvent>> events,
    required String today,
    required String? month,
    required ({String min, String max})? range,
    required String? lineMode,
    required List<Category> categories,
    required List<Tag> tags,
  }) {
    final data = events.value;
    // **失敗を「空」に潰さない。** 前回の値がある間は出したまま差し替え、
    // 値が 1 度も無い時だけ失敗を出す
    if (data == null || month == null || range == null) {
      return [
        SliverToBoxAdapter(
          child: events.hasError
              ? LoadFailure(onRetry: _reload)
              : const InitialLoading(),
        ),
      ];
    }

    final t = ref.watch(messagesProvider);
    // 絞り込み中はグリッドもリストも同じ範囲を見る。**グリッドにも絞り込み後を
    // 渡す**（gyumesy で、素の予定を渡していたためにタグを押しても線と丸ポチが
    // 1 つも減らなかった）。`lineMode` は**線を引くかどうか**にも効くので続けて渡す
    final shown = _filtered(data, lineMode);
    final weeks = buildMonthGrid(shown, month, lineMode, today);
    final monthDays = buildMonthDays(shown, month, today);
    // 日リストの縦線。**月グリッドと同じで、カテゴリを選んでいる時だけ引く**
    final lanes = buildDayLanes(
      shown,
      [for (final d in monthDays) d.date],
      today,
      category: lineMode,
    );
    final sheet = (
      today: today,
      shown: shown,
      categories: categories,
      tags: tags,
    );

    return [
      SliverPadding(
        // 上は帯の `mb-6`（24）
        padding: const EdgeInsets.fromLTRB(
          CalendarPage.pageInset,
          24,
          CalendarPage.pageInset,
          0,
        ),
        sliver: SliverToBoxAdapter(
          // **グリッドと日リストの両方で払える。** web も `[data-calendar-swipe]` を
          // 2 か所に張っている。帯を貼り付けたので、日リストを読んでいる最中の
          // 指はリストの上にある
          child: GestureDetector(
            onHorizontalDragStart: (details) {
              _dragX = 0;
              _dragStart = details.sourceTimeStamp ?? Duration.zero;
              _dragEnd = _dragStart;
            },
            onHorizontalDragUpdate: (details) {
              _dragX += details.delta.dx;
              // 離した時の `DragEndDetails` は時刻を持たないので、
              // 最後の更新の時刻を控えておく
              _dragEnd = details.sourceTimeStamp ?? _dragEnd;
            },
            onHorizontalDragEnd: (details) {
              // **web と同じしきい値・同じ測り方**（`swipe.ts`）。縦優位の払いは
              // 一覧が取り、ここへは届かない（gyumesy の実測）
              if (_dragX.abs() < CalendarPage.swipeMinPx) return;
              final elapsed = (_dragEnd - _dragStart).inMilliseconds;
              final speed = _dragX.abs() / (elapsed < 1 ? 1 : elapsed);
              if (speed < CalendarPage.swipeMinVelocity) return;
              _shiftMonth(_dragX < 0 ? 1 : -1, month, range);
            },
            child: Column(
              children: [
                MonthGrid(
                  weeks: weeks,
                  activeEventIds: _activeInGrid ? _activeEventIds : const {},
                  selectedDate: _selectedDate,
                  monthKey: month,
                  today: today,
                  weekdays: t.calendarWeekdays,
                  eventCountLabel: t.calendarEventCount,
                  onTapDay: (date) => _openDay(date, sheet),
                  onTapEvents: (date, events) =>
                      _openEvents(date, events, sheet),
                ),
                // グリッドと日リストの間（web の `mt-8`）
                const SizedBox(height: 32),
                // **月の全日をリストでも出す。** グリッドは俯瞰で、こちらは中身を
                // 読むためのもの（web も両方置いている）。**一括で組む**
                // （[_goToToday]。1 か月は最大 31 行なので全部組んでも軽い）
                for (final day in monthDays)
                  CalendarDayRow(
                    key: day.isToday ? _todayKey : null,
                    day: day,
                    showMonthHeading: day != monthDays.first && day.day == 1,
                    lines: lanes.linesOn(day.date),
                    laneCount: lanes.laneCount,
                    selected: day.date == _selectedDate,
                    activeEventIds: _activeInGrid ? const {} : _activeEventIds,
                    categories: categories,
                    tags: tags,
                    onOpenArticle: widget.onOpenArticle,
                    onTapDay: () => _openDay(day.date, sheet),
                    // **印を押したらその予定だけ**（月グリッドの線・丸ポチと同じ）
                    onTapEvent: (e) =>
                        _openEvents(day.date, [e], sheet, fromGrid: false),
                    // **線を押したらその期間の予定をまとめて出す**
                    // （web の線は `data-event-ids` を複数持つ）
                    onTapLine: (ids) => _openEvents(
                      day.date,
                      [
                        for (final e in shown)
                          if (ids.contains(e.id)) e,
                      ],
                      sheet,
                      fromGrid: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ];
  }
}

/// シートを開くのに要るもの（`build` で作って渡す）。
typedef _SheetContext = ({
  String today,
  List<CalendarEvent> shown,
  List<Category> categories,
  List<Tag> tags,
});

/// 見出し。web の `calendar.astro` の h1（`pb-2 mb-6 border-b-2
/// border-brand-primary-text`）。**下線は地の上に置く赤（`primaryText`）**
/// （gyumesy はピンク。塗りの `primary` はダークで 3:1 に届かない）。
class CalendarHeader extends ConsumerWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;

    return Padding(
      // web の `pt-4`（16）。下は h1 の `mb-6`（24）
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Container(
        width: double.infinity,
        // web の h1 の `pb-2`
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.primaryText, width: 2),
          ),
        ),
        child: Semantics(
          header: true,
          child: Text(
            t.calendarPageTitle,
            style: TextStyle(
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
        ),
      ),
    );
  }
}

/// 貼り付く帯の中身（月ナビ・カテゴリ・子フィルタ）。web の `CoCalendarControls`。
///
/// web の器は `py-2 flex flex-col gap-2` で、子フィルタはカテゴリを選んだ時だけ
/// 出す（`hidden`）。**gap は子が消えれば一緒に消える**ので、こちらも間隔を
/// 「子があるときだけ」置く（gyumesy の注記）。
///
/// **左右の余白は帯ではなく各段が持つ**（web: 月ナビは `mx-4`、チップの段は
/// `px-4`）。帯に持たせると、横に流すチップの段がその内側で切れ、画面の端より
/// 手前でチップが途切れる（web のユーザーの指摘）。gyumesy は浮いたカードの
/// 器が余白を持っていた。
///
/// テストから直接組めるよう公開している（高さの積み上がりは画面ごと組まないと
/// 確かめられない）。
class CalendarToolbar extends StatelessWidget {
  const CalendarToolbar({
    required this.month,
    required this.range,
    required this.onShift,
    required this.onToday,
    required this.categories,
    required this.lineMode,
    required this.onSelectLineMode,
    required this.childTags,
    required this.selectedChildTags,
    required this.onToggleChildTag,
    super.key,
  });

  final String month;
  final ({String min, String max}) range;
  final ValueChanged<int> onShift;
  final VoidCallback onToday;
  final List<Category> categories;
  final String? lineMode;
  final ValueChanged<String?> onSelectLineMode;

  /// 選んでいるカテゴリに実際にあるタグ。**空なら行ごと出さない。**
  final List<Tag> childTags;
  final Set<String> selectedChildTags;
  final ValueChanged<String> onToggleChildTag;

  /// 要素どうしの間隔。web の器の `gap-2`。
  static const gap = 8.0;

  /// 帯の上下の余白。web の `py-2`。
  static const bandPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: bandPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            // web の月ナビの `mx-4`
            padding: const EdgeInsets.symmetric(
              horizontal: CalendarPage.pageInset,
            ),
            child: CalendarMonthBar(
              month: month,
              range: range,
              onShift: onShift,
              onToday: onToday,
            ),
          ),
          const SizedBox(height: gap),
          _CategoryChips(
            categories: categories,
            selected: lineMode,
            onSelect: onSelectLineMode,
          ),
          // **子フィルタが 0 件なら間隔ごと出さない。** 間隔だけ残すと、その
          // カテゴリを選んだ瞬間に 8pt の空白が黙って開く（gyumesy の注記）
          if (childTags.isNotEmpty) ...[
            const SizedBox(height: gap),
            _ChildTagChips(
              tags: childTags,
              selected: selectedChildTags,
              onToggle: onToggleChildTag,
            ),
          ],
        ],
      ),
    );
  }
}

/// 月ナビ。**画面の上に置く。** カレンダーは「今どの月か」がまず見えることが要。
///
/// テストから直接組めるよう公開している（狭い端末での重なりと、文字サイズを
/// 上げた時の切れは、画面ごと組まないと確かめられない類の壊れ方をする）。
class CalendarMonthBar extends ConsumerWidget {
  const CalendarMonthBar({
    required this.month,
    required this.range,
    required this.onShift,
    required this.onToday,
    super.key,
  });

  final String month;
  final ({String min, String max}) range;
  final ValueChanged<int> onShift;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    final parts = month.split('-');

    // **月ラベルは画面中央ではなく、「今日」を除いた領域の中央（意図した差分。
    // gyumesy から写した判断）。** web は `absolute right-0` で「今日」を浮かせて
    // 中央寄せにしているが、それだと端末の文字サイズを上げた時に「今日」が
    // 「次の月」に重なる（gyumesy の実測で x2.0 から。x3.0 では矢印 36pt の
    // 大半が覆われ、押すたび今月へ戻される）。**中央寄せに戻さないこと** ——
    // ずれは 320pt に対して 8%（「今日」の幅の半分）で月は読めるが、重なるほうは
    // 次の月へ行く手段が消える。
    //
    // web の月ナビ行は `h-9`（36）。矢印も `w-9 h-9`
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          _NavButton(
            // **端では押せなくする。** 空の月へいくらでも進めると戻り方が
            // 分からなくなる（web も `disabled:opacity-25` で残しつつ殺す）
            onPressed: month.compareTo(range.min) <= 0
                ? null
                : () => onShift(-1),
            icon: Icons.arrow_back_ios,
            tooltip: t.calendarPrevMonth,
          ),
          Expanded(
            // **端末の文字サイズを上げても切らない。** 縮めて収める
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                t.calendarMonthLabel(int.parse(parts[0]), int.parse(parts[1])),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                  // 月をまたいでも見出しの幅が動かないように
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _NavButton(
            onPressed: month.compareTo(range.max) >= 0
                ? null
                : () => onShift(1),
            icon: Icons.arrow_forward_ios,
            tooltip: t.calendarNextMonth,
          ),
          OutlinedButton(
            onPressed: onToday,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textSub,
              side: BorderSide(color: colors.border),
              // web の `px-3 py-1.5`（12 / 6）
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
            ),
            child: Text(
              t.calendarToday,
              // web の `text-[13px] leading-none`
              style: const TextStyle(fontSize: 13, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

/// 月送りの矢印。web の `w-9 h-9`（36×36）の丸ボタン。
///
/// `IconButton` を使わないのは、既定の当たり判定（48×48）が行の高さ（36）を
/// 超えて上下に溢れ、帯の高さが web と食い違うため（gyumesy の注記）。
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        child: InkResponse(
          onTap: onPressed,
          radius: 18,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 13,
              // web の `disabled:opacity-25`
              color: colors.textSub.withValues(
                alpha: onPressed == null ? 0.25 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 線を引くカテゴリの選択。**凡例も兼ねる。**
///
/// 排他選択で、選んだカテゴリの予定と線だけを出す。既定の「すべて」は線なしで
/// 全カテゴリの予定を出すモード（線を 1 カテゴリに絞らないと、常時並走する
/// キャンペーンや一時閉店で画面が線だらけになる）。
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);

    return Semantics(
      label: t.calendarLineCategoryGroup,
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // web の段の `px-4`。**余白は段の内側に持つ**（横に流した時に画面の
        // 端まで届く。[CalendarToolbar] の doc）
        padding: const EdgeInsets.symmetric(horizontal: CalendarPage.pageInset),
        child: Row(
          children: [
            // **記事一覧の絞り込みと同じチップ**（web も `CoArticleFilter` と
            // `CoCalendarControls` で同じ値を持つ）。選択中はそのカテゴリの色で
            // 示す —— 文字＝カテゴリ色、地＝色の 6%、枠＝色の 35%。
            //
            // **地は 6%**（gyumesy は 10%）。web の実測で、10% だと選択中の
            // 「キャンペーン」がライトで 4.44:1 と文字の基準に届かない。未選択の
            // 文字も薄めない（gyumesy は 60%。web はライトで 2.55:1 を踏んでいる）。
            //
            // **一律の地色で塗らないこと。** チップは線の凡例も兼ねているので、
            // 選んだチップとカレンダーに引かれる線が同じ色で結びつく必要がある
            FilterChipButton.all(
              label: t.calendarAll,
              selected: selected == null,
              onTap: () => onSelect(null),
            ),
            for (final category in categories) ...[
              // web の器の `gap-1`
              const SizedBox(width: 4),
              FilterChipButton.category(
                label: category.label,
                slug: category.slug,
                selected: selected == category.slug,
                onTap: () => onSelect(category.slug),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// カテゴリの中をさらに絞るタグ。**複数選べる。**
///
/// **未選択のチップは日リストのタグと同じ見た目にする**（これはタグだ、と
/// 伝える）。押して絞り込み中のものだけ地を反転させる。
class _ChildTagChips extends StatelessWidget {
  const _ChildTagChips({
    required this.tags,
    required this.selected,
    required this.onToggle,
  });

  final List<Tag> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // **左右を親の段より 3px 内へ寄せる（光学調整）。** web の `px-[19px]`
      // （段の余白 16 ＋ 3）。web のコメント:「親チップは rounded-full で角が
      // 丸く逃げるため、左端を数値で揃えると角ばった子フィルタの方が左に
      // はみ出して見える」
      padding: const EdgeInsets.symmetric(
        horizontal: CalendarPage.pageInset + 3,
      ),
      child: Row(
        children: [
          for (final tag in tags) ...[
            // web の器の `gap-1.5`
            if (tag != tags.first) const SizedBox(width: 6),
            // **記事一覧の下の段と同じチップ**。未選択は日リストのタグと同じ
            // 見た目（web の `bg-brand-text/8`）で「これはタグだ」と伝え、押して
            // 絞り込み中のものだけ地を反転させる（本文色と面色の入れ替え。
            // gyumesy の `fill` / `onFill` は使わない —— web の注記）。親チップの
            // 丸と違って**角丸は 4**（別の階層の絞り込みだと形で分かる）
            TagToggleChip(
              label: tag.label,
              selected: selected.contains(tag.slug),
              onTap: () => onToggle(tag.slug),
            ),
          ],
        ],
      ),
    );
  }
}
