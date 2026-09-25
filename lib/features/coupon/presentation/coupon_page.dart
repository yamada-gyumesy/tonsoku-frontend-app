import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/config/app_config.dart';
import 'package:tonsoku/core/config/app_config_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/lifecycle/app_resume.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/article/presentation/article_page.dart';
import 'package:tonsoku/features/article/presentation/widgets/image_viewer.dart';
import 'package:tonsoku/features/coupon/data/coupon_repository.dart';
import 'package:tonsoku/features/coupon/domain/coupon_best_deal.dart';
import 'package:tonsoku/features/coupon/domain/coupon_row.dart';
import 'package:tonsoku/features/coupon/domain/coupon_schedule.dart';
import 'package:tonsoku/features/coupon/presentation/widgets/coupon_best_card.dart';
import 'package:tonsoku/features/coupon/presentation/widgets/coupon_list.dart';
import 'package:tonsoku/features/coupon/presentation/widgets/coupon_schedule_chart.dart';
import 'package:tonsoku/features/coupon/presentation/widgets/coupon_types_table.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/home/presentation/header_hide_controller.dart';
import 'package:tonsoku/features/shell/presentation/widgets/tonsoku_app_bar.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/coupon.dart';
import 'package:tonsoku/shared/widgets/async_list_view.dart';
import 'package:tonsoku/shared/widgets/section_heading.dart';

/// クーポンタブ。**web の `/coupon/`（`src/pages/[...locale]/coupon.astro`）と
/// 同じ構成。**
///
/// 見出し＋共有 → 但し書き → 種類表 → 現在使えるクーポン → 最大還元率 →
/// 今後の予定 → スケジュール。
///
/// ## web との違い
///
/// - **スケジュールの見出しに「カレンダーをみる」を置いていない。** カレンダーは
///   メニューの Issue で入る（それまでは行き先が無い）。入れる時は web と同じく
///   **キャンペーンで絞った状態**へ飛ばす
/// - **記事へのリンクは記事の全件（`index.json`）に居る slug だけ**（web の
///   `fetchArticles`）。フィード（200 件）で見ると、古い記事を指す施策が
///   リンクにならない
class CouponPage extends ConsumerStatefulWidget {
  const CouponPage({required this.onOpenArticle, super.key});

  final ValueChanged<String> onOpenArticle;

  /// 本文の左右の余白（web の `px-4`）。スケジュールの帯の幅もこれから出す。
  static const pageInset = 16.0;

  /// 共有の中身。**組み立てだけを切り出してある**（`SharePlus.instance` を
  /// 差し替えられないので、ここを直接テストする。記事の共有と同じ）。
  @visibleForTesting
  static ShareParams shareParamsFor({
    required AppConfig config,
    required AppLocale locale,
    required AppMessages t,
  }) => ShareParams(
    title: t.couponPageTitle,
    subject: t.couponPageTitle,
    uri: Uri.parse(config.siteUrl('/coupon/', locale)),
  );

  @override
  ConsumerState<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends ConsumerState<CouponPage> {
  /// ロゴバーの退避量（ホームと同じ）。
  final _headerHidden = HeaderHideController(maxHidden: TonsokuAppBar.height);

  /// 取り直しを二重に走らせないためだけに持つ（ホームと同じ）。
  bool _reloading = false;

  @override
  void dispose() {
    _headerHidden.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_reloading) return;
    _reloading = true;
    // **`await` の前に容れ物を捕まえる**（`pullToRefresh` の doc と同じ理由）
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await refreshCouponLists(container);
    } finally {
      _reloading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // **アクティブ復帰で取り直す。** 期限つきの施策を並べる画面なので、
    // 開き直した時に終わったものが残っていると成り立たない
    listenAppResume(ref, _reload);

    final colors = context.colors;
    final topInset = MediaQuery.paddingOf(context).top + TonsokuAppBar.height;
    final coupon = ref.watch(couponProvider);

    return Scaffold(
      backgroundColor: colors.page,
      body: NotificationListener<ScrollUpdateNotification>(
        onNotification: _headerHidden.handleScroll,
        child: Stack(
          children: [
            RefreshIndicator(
              edgeOffset: topInset,
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ヘッダーに潜り込ませるぶんの余白 ＋ web の `pt-4`
                  SliverToBoxAdapter(child: SizedBox(height: topInset + 16)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      CouponPage.pageInset,
                      0,
                      CouponPage.pageInset,
                      32,
                    ),
                    sliver: SliverToBoxAdapter(
                      // **失敗を「空」に潰さない。** 前回の値がある間は出したまま
                      // 差し替え、値が 1 度も無い時だけ失敗を出す
                      child: switch (coupon) {
                        AsyncValue(:final value?) => _Body(
                          coupon: value,
                          onOpenArticle: widget.onOpenArticle,
                        ),
                        AsyncValue(hasValue: true) => _Body(
                          coupon: null,
                          onOpenArticle: widget.onOpenArticle,
                        ),
                        AsyncError() => LoadFailure(
                          onRetry: () => ref.invalidate(couponProvider),
                        ),
                        _ => const InitialLoading(),
                      },
                    ),
                  ),
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
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.coupon, required this.onOpenArticle});

  /// **null は「配信が無い」**（`coupon.json` がまだ置かれていない）。
  /// 見出し・但し書き・種類表と「ありません」だけを出す。
  final Coupon? coupon;
  final ValueChanged<String> onOpenArticle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    final locale = ref.watch(localeControllerProvider);
    final tags = ref.watch(tagsProvider).value ?? const [];
    final tagLabels = {for (final tag in tags) tag.slug: tag.label};
    // **記事の全件で見る**（施策は記事より寿命が長い。フィードの 200 件で
    // 見ると、古い記事を指す施策がリンクにならない）。全件がまだ届いていない間は
    // フィードで代える
    final slugs = <String>{
      for (final a
          in ref.watch(articleIndexProvider).value ??
              ref.watch(feedProvider).value ??
              const <ArticleMeta>[])
        a.slug,
    };

    final data = coupon;
    final rows = data == null
        ? const <CouponRow>[]
        : offerRows(
            data,
            locale: locale,
            t: t,
            tagLabels: tagLabels,
            slugs: slugs,
          );
    final upcoming = data == null
        ? const <CouponRow>[]
        : upcomingRows(
            data,
            locale: locale,
            t: t,
            tagLabels: tagLabels,
            slugs: slugs,
          );
    final best = data == null
        ? null
        : bestDealView(coupon: data, t: t, tagLabels: tagLabels, slugs: slugs);
    final trackWidth = scheduleTrackWidth(
      MediaQuery.sizeOf(context).width - CouponPage.pageInset * 2,
    );
    final schedule = data == null
        ? null
        : buildSchedule(
            coupon: data,
            t: t,
            tagLabels: tagLabels,
            formatMonthDay: (iso) => formatMonthDay(iso, locale),
            today: clock.now(),
            measureLabel: (label) =>
                measureScheduleLabel(label, trackWidth: trackWidth),
          );
    // 時点は日付まで（時刻まで出すと、配信のたびに変わって見える。web と同じ）
    final generatedAt = data == null
        ? null
        : DateTime.tryParse(data.generatedAt);

    void openLink(String url) {
      final uri = Uri.tryParse(url);
      if (uri != null) launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    }

    void openImage(CouponRowImage image) => showImageViewer(
      context,
      url: image.url,
      alt: image.label,
      isCode: image.isCode,
      source: image.source,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Title(
          title: t.couponPageTitle,
          shareLabel: t.commonShare,
          onShare: () => SharePlus.instance.share(
            CouponPage.shareParamsFor(
              config: ref.read(appConfigProvider),
              locale: locale,
              t: t,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          t.couponDisclaimer,
          style: TextStyle(fontSize: 11, height: 1.625, color: colors.textSub),
        ),
        const SizedBox(height: 24),
        // 用語はここで一度だけ説明する（下の一覧は名前・期限・数字だけで読める
        // 状態にする）
        const CouponTypesTable(),
        const SizedBox(height: 32),

        // 1. 現在使えるクーポン。**空でも節を残す**（空＝今日使えるものが無い、
        // という情報そのものになる）
        SectionHeading(
          label: t.couponOffersHeading,
          // **時点は一覧の見出しに添える。** この日付が効くのは一覧の中身で、
          // ページの上に置くと何の日付か分からない
          trailing: generatedAt == null
              ? null
              : Text(
                  t.couponUpdatedAt(formatDateOnly(generatedAt, locale)),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSub,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              t.couponOffersEmpty,
              style: TextStyle(fontSize: 14, color: colors.textSub),
            ),
          )
        else
          CouponList(
            rows: rows,
            onOpenArticle: onOpenArticle,
            onOpenLink: openLink,
            onOpenImage: openImage,
          ),
        const SizedBox(height: 32),

        // 2. 現在の最大還元率。**ランクの切替は置かない**（最大の話なので
        // 配信が選んだランクで固定）
        if (best != null) ...[
          CouponBestCard(view: best, onOpenArticle: onOpenArticle),
          const SizedBox(height: 32),
        ],

        // 3. 今後の予定。**1 件も無い日は節ごと出さない**（見出しと
        // 「ありません」だけが残るのは情報にならない）
        if (upcoming.isNotEmpty) ...[
          SectionHeading(label: t.couponUpcomingHeading),
          const SizedBox(height: 12),
          CouponList(
            rows: upcoming,
            upcoming: true,
            onOpenArticle: onOpenArticle,
            onOpenLink: openLink,
            onOpenImage: openImage,
          ),
          const SizedBox(height: 32),
        ],

        // 4. スケジュール。**帯が 1 本も無い日は節ごと出さない**
        if (schedule != null && schedule.bars.isNotEmpty) ...[
          SectionHeading(label: t.couponScheduleHeading),
          const SizedBox(height: 12),
          CouponScheduleChart(schedule: schedule),
        ],
      ],
    );
  }
}

/// ページの見出し＋共有ボタン。**下線は見出しではなく囲みが持つ**（見出しに
/// 付けると下線が文字幅で切れて、右のボタンが線の外に浮く。web と同じ）。
class _Title extends StatelessWidget {
  const _Title({
    required this.title,
    required this.shareLabel,
    required this.onShare,
  });

  final String title;
  final String shareLabel;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.primaryText, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ShareButton(tooltip: shareLabel, onPressed: onShare),
        ],
      ),
    );
  }
}
