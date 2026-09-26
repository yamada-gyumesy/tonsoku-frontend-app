import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/analytics/screen_path.dart';
import 'package:tonsoku/core/analytics/track_screen.dart';
import 'package:tonsoku/core/config/app_config_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/lifecycle/app_resume.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/article/presentation/widgets/back_to_list.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/home/data/article_repository.dart';
import 'package:tonsoku/features/notifications/data/messaging_service.dart';
import 'package:tonsoku/features/notifications/presentation/notification_settings_controller.dart';
import 'package:tonsoku/features/notifications/presentation/widgets/notification_sample.dart';
import 'package:tonsoku/features/notifications/presentation/widgets/notification_toggle_row.dart';
import 'package:tonsoku/shared/models/category.dart';
import 'package:tonsoku/shared/utils/pull_to_refresh.dart';
import 'package:tonsoku/shared/widgets/app_toast.dart';
import 'package:tonsoku/shared/widgets/auto_slider.dart';
import 'package:tonsoku/shared/widgets/back_header.dart';

/// 通知設定。web の `notifications.astro`（gyumesy-frontend-app の
/// `NotificationSettingsPage` を写し、見た目をとん速の web に合わせ直した）。
///
/// **振る舞いは gyumesy のまま**: マスター 1 行（OS の許可そのもの）＋ カテゴリ行で、
/// **保存ボタンは無く、触った時点で反映する**。web の「有効にする」ボタン・
/// 「設定を保存」ボタンの作りはブラウザの事情（許可を求めた後でないとトークンが
/// 取れない・サーバーへまとめて送る）なので写さない。
///
/// ## gyumesy との違い
///
/// - **上は「＜ 戻る」の帯**（`BackHeader`。ランキング・カレンダーと同じ、
///   メニューから開く画面の顔）。gyumesy は `AppBar`
/// - **見出しの下線は `primaryText`**（web の `border-brand-primary-text`。
///   塗りの `primary` を地の上に置かない）
/// - **サンプルは説明の箱の外**（web のとん速版の並び。gyumesy は箱の中）。
///   中身は web の見本の絵と同じ題材だが、**絵ではなくウィジェットで描き、
///   表示言語で出す**（[NotificationSample]。web は全ロケールで日本語の絵）
/// - RSS は**そのロケールのフィードに記事がある時だけ**そのロケールの URL を写す
///   （web の `hasLocaleFeed`。無いロケールの `feed.xml` は 404）
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  /// 本文の左右余白（web の `px-4`）。**罫線だけは画面いっぱいに伸ばしたい**ので、
  /// 一覧側ではなく要素ごとに持たせる。
  static const gutter = 16.0;

  /// 左右を空ける。
  static Widget inset(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: gutter),
    child: child,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    final state = ref.watch(notificationSettingsControllerProvider);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];

    // **戻ってくるたびに権限を見直す。** 設定アプリで切られてもアプリは
    // 動いたままなので、開きっぱなしだと許可済みの画面が残る
    listenAppResume(ref, () {
      final controller = ref.read(
        notificationSettingsControllerProvider.notifier,
      );
      controller.refresh();
      // **生きたまま戻れたので印は要らない。** 消さないと、次に普通に
      // 起動した時までこの画面が開く
      controller.clearReturning();
    });

    return TrackScreen(
      screen: ScreenPath.notifications(ref.watch(localeControllerProvider), t),
      child: Scaffold(
        backgroundColor: colors.page,
        body: Stack(
          children: [
            Column(
              children: [
                BackHeader(onBack: () => backFromArticle(context)),
                Expanded(
                  child: RefreshIndicator(
                    // **カテゴリは配信から引いている**ので取り直せる必要がある。
                    // 権限も一緒に見直す（設定アプリで変えて戻った時のため）
                    // **温めた後に貼り直す**（理由は [pullToRefresh]）
                    onRefresh: () => pullToRefresh(
                      context,
                      warm: (c) =>
                          c.read(articleRepositoryProvider).refreshCategories(),
                      reattach: (c) {
                        c.invalidate(categoriesProvider);
                        // **画面を閉じた後でも安全** —— 容れ物越しなので `ref` の
                        // 生き死にに依らない
                        unawaited(
                          c
                              .read(
                                notificationSettingsControllerProvider.notifier,
                              )
                              .refresh(),
                        );
                      },
                    ),
                    child: ListView(
                      // **左右は空けない。** 罫線を画面いっぱいに引くため。
                      // 文字の内側の余白は各要素が持つ（[inset]）。
                      //
                      // web の `pt-4 pb-8`。**下はシステムバーのぶんを足す** ——
                      // Android のナビゲーションバーが最後の行に重なって押せなくなる
                      // （gyumesy が実機で踏んだ）
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        0,
                        16,
                        0,
                        32 + MediaQuery.paddingOf(context).bottom,
                      ),
                      children: [
                        inset(const _Heading()),
                        // web の見出しの `mb-6`
                        const SizedBox(height: 24),
                        inset(const _Intro()),
                        // web の説明の箱の `mb-8`
                        const SizedBox(height: 32),
                        inset(
                          Text(
                            t.notificationsSampleLabel,
                            // web の `mb-2 text-xs text-brand-text-sub`
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSub,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        inset(
                          AutoSlider(
                            // **テーマごとに色を変える。** 見本は面色を持つ
                            // カードなので、1 種類だとどちらかのテーマで地に
                            // 沈む（ライトは明るい灰、ダークは黒の半透明）
                            items: NotificationSample.all(
                              t,
                              ref.watch(localeControllerProvider),
                              Theme.of(context).brightness,
                            ),
                            aspectRatio: NotificationSample.aspectRatio,
                            // web の `visibleCount={2.7} visibleCountSp={1} gap={16}`
                            visibleCount: 2.7,
                            visibleCountSp: 1,
                            gap: 16,
                          ),
                        ),
                        // web のサンプルの `mb-8`
                        const SizedBox(height: 32),
                        _Panel(state: state, categories: categories),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // web の `CaLoading`（`fixed inset-0 bg-black/30`）。
            // **マスターを操作している間だけ**出す（カテゴリの反映は行ごとに
            // 見せるので全画面を覆わない）。
            // **下の操作を通さない** —— `ColoredBox` は子の外を素通りさせる。
            // **開いた直後の読み込みでは出さない**（権限を読むだけの一瞬で、
            // 暗幕が点滅して見える。その間は `_Panel` が「読み込み中」を出す）
            if (state.loading && state.permission != null)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Color(0x4D000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 見出し行。**下線は見出しではなく囲みが持つ**（`h1` に付けると線が文字幅で
/// 切れて右の RSS が浮く。gyumesy と同じ）。
///
/// web の `flex items-end justify-between gap-4 pb-2 border-b-2
/// border-brand-primary-text`。
class _Heading extends ConsumerWidget {
  const _Heading();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.primaryText, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                t.notificationsTitle,
                // web の `text-[1.25rem] font-bold`
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.text,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // **RSS は web と同じくここに置く。** 通知以外の購読手段で、
          // アプリでも読む人は読む
          const _RssLink(),
        ],
      ),
    );
  }
}

class _RssLink extends ConsumerWidget {
  const _RssLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    // **押す前から購読しておく**（[_feedUrl] が見る）。押した時に初めて `read`
    // すると、まだ取得中で「無い」と見なして日本語に落ちる
    final url = _feedUrl(ref);

    return Semantics(
      label: t.notificationsRssAria,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        // **開かずに URL を写す。** フィードは XML なので、開いても読めるものが
        // 出てこない。読む人が欲しいのは**購読先に貼る URL**（web も同じ）
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: url));
          if (!context.mounted) return;
          AppToast.show(context, t.notificationsRssCopied);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rss_feed, size: 18, color: colors.textSub),
              Text(
                'RSS',
                // web の `text-[0.5625rem] font-bold`
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: colors.textSub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 写すフィードの URL。**そのロケールに記事がある時だけ、そのロケールの
  /// フィード**（web の `hasLocaleFeed`）。
  ///
  /// web の `rss.mts` は**記事が 1 件も無いロケールの `feed.xml` を書かない**ので、
  /// 無い時に指すと 404 を写すことになる。**リンクなら押して初めて分かるが、
  /// 写した URL は購読先で初めて失敗する**（web の注記）。日本語は必ず出るので、
  /// 分からない間（一覧をまだ取れていない）も日本語に落とす。
  static String _feedUrl(WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final locale = ref.watch(localeControllerProvider);
    final hasFeed =
        locale == AppLocale.ja ||
        (ref.watch(feedProvider).value?.isNotEmpty ?? false);
    return config.siteUrl('/feed.xml', hasFeed ? locale : AppLocale.ja);
  }
}

/// 説明の箱。web の `mb-8 p-4 bg-brand-bg rounded-lg`。
class _Intro extends ConsumerWidget {
  const _Intro();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    // web の `text-[0.9375rem] text-brand-text leading-relaxed`
    final body = TextStyle(fontSize: 15, height: 1.625, color: colors.text);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.notificationsIntro1, style: body),
          const SizedBox(height: 8),
          Text(t.notificationsIntro2, style: body),
          // **日本語では空文字なので出さない**（プッシュは日本語のみ配信）。
          // web の `mt-4 text-xs text-brand-primary-text`
          if (t.notificationsLocaleNotice.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              t.notificationsLocaleNotice,
              style: TextStyle(fontSize: 12, color: colors.primaryText),
            ),
          ],
        ],
      ),
    );
  }
}

/// 中身。**マスター 1 行 ＋ カテゴリ行**で、保存ボタンは無い。
///
/// **マスターが切れている間もカテゴリ行は出す。** 隠すと「何が届くのか」が
/// 分からないまま許可を求めることになる。**値は残したまま触らせないだけ。**
class _Panel extends ConsumerWidget {
  const _Panel({required this.state, required this.categories});

  final NotificationSettingsState state;
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;
    final controller = ref.read(
      notificationSettingsControllerProvider.notifier,
    );

    if (state.loading && state.permission == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Text(
            t.commonLoading,
            style: TextStyle(fontSize: 14, color: colors.textSub),
          ),
        ),
      );
    }

    final enabled = state.enabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // **見出しは画面の題と同じ言葉でよい。** ここは「通知そのものの
        // オン・オフ」で、下の「トピック別設定」と対になる
        NotificationSettingsPage.inset(
          NotificationSectionLabel(t.notificationsTitle),
        ),
        NotificationRowGroup(
          children: [
            NotificationToggleRow(
              label: t.notificationsMasterLabel,
              // **アプリからは切り替えられないことを先に言う。** 許可済みの
              // 通知をアプリ側から取り消す API は iOS にも Android にも無い
              description: t.notificationsMasterHintOs,
              value: enabled,
              onChanged: (on) => _onMaster(context, ref, on: on),
            ),
          ],
        ),
        // **全体の行とカテゴリを離す。** 囲みも地色も太字も使わないので、
        // 余白と見出しで階層を見せる
        const SizedBox(height: 28),
        NotificationSettingsPage.inset(
          NotificationSectionLabel(t.notificationsTopicsHeading),
        ),
        // **切れている間は、まとめて薄くする。** 1 行ずつ薄くしても
        // 「押せない」に見えず、押して何も起きない行になる
        Opacity(
          opacity: enabled ? 1 : 0.4,
          child: NotificationRowGroup(
            children: [
              for (final category in categories)
                NotificationToggleRow(
                  label: category.label,
                  description: category.description,
                  value: state.topics.isOn(category.slug),
                  // **全体が切れている間・反映中は触らせない**
                  onChanged: enabled && !state.pending.contains(category.slug)
                      ? (on) async {
                          final ok = await controller.toggle(
                            category.slug,
                            on: on,
                          );
                          if (!context.mounted || ok) return;
                          AppToast.show(context, t.commonError, isError: true);
                        }
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// マスターを押した時。
  ///
  /// - **まだ聞いていない** → OS のダイアログを出す
  /// - **それ以外** → 設定アプリを開く。**許可の取り消しも付与も、アプリからは
  ///   できない**（OS がそういう API を持っていない）ので、行き先は 1 つ
  Future<void> _onMaster(
    BuildContext context,
    WidgetRef ref, {
    required bool on,
  }) async {
    final t = ref.read(messagesProvider);
    final controller = ref.read(
      notificationSettingsControllerProvider.notifier,
    );

    if (on && state.permission == NotificationPermission.notDetermined) {
      // **カテゴリがまだ届いていなくても進めてよい。** 空なら何も保存しない
      // ので（[NotificationSettingsController.enableMaster]）、「許可したのに
      // 購読 0 件のまま戻らない」にはならない
      final ok = await controller.enableMaster([
        for (final c in categories) c.slug,
      ]);
      if (!context.mounted || ok) return;
      AppToast.show(context, t.commonError, isError: true);
      return;
    }
    await controller.openSettings();
  }
}
