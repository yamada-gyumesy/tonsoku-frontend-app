import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/config/app_config_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/purchase/remove_ads_controller.dart';
import 'package:tonsoku/core/purchase/remove_ads_result_text.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/utils/article_date.dart';
import 'package:tonsoku/features/calendar/data/calendar_repository.dart';
import 'package:tonsoku/features/calendar/domain/calendar_window.dart';
import 'package:tonsoku/features/menu/presentation/app_version_provider.dart';
import 'package:tonsoku/features/menu/presentation/licenses_page.dart';
import 'package:tonsoku/features/menu/presentation/widgets/menu_list_row.dart';
import 'package:tonsoku/features/menu/presentation/widgets/theme_switch.dart';
import 'package:tonsoku/features/ranking/data/ranking_repository.dart';
import 'package:tonsoku/features/ranking/domain/ranking_entries.dart';
import 'package:tonsoku/shared/widgets/app_toast.dart';

/// 画面下のナビ「メニュー」から開くボトムシート。web の `CoMenuSheet`
/// （gyumesy-frontend-app の `MenuSheet` を写した）。
///
/// **ナビはこのシートより上に置き、暗幕もナビには掛けない。** 押した本人のタブが
/// 隠れず、もう一度押せば閉じられる。他のタブへも直接移れる（web と同じ）。
/// そのため `showModalBottomSheet` を使わず、`AppShell` の本文の上に重ねている
/// （`showModalBottomSheet` は画面全体を覆うのでナビまで暗くなる）。
///
/// **利用規約・プライバシーポリシー・ライセンス表記は見出し右の「…」へ
/// 寄せる（アプリ独自。gyumesy と同じ）。** web はフッターに常設していてメニューには
/// 置かないが、**アプリはフッターを持たない**ので、どこかに入口が要る。ただし読む
/// 頻度は最も低いので、本体の並びより目立たせない。
///
/// ## web・gyumesy との違い
///
/// - **カレンダー・ランキングはここに詰める**（とん速の下タブは ホーム / マップ /
///   クーポン / メニュー。ユーザーの指定）
/// - **並びは「とん速とは → カレンダー → ランキング → 通知設定 → 外観 → 言語」**
///   （ユーザーの指定）。web のメニューとも gyumesy とも違う
/// - **通知設定の行は常に出す**（web と同じ。配信の有無に依らない面なので、
///   カレンダー・ランキングのように中身で閉じる対象ではない）
/// - **広告を外す課金の 2 行（「広告を非表示にする」「購入を復元」）を末尾に
///   常に置く**（アプリ独自。Issue #42。導線はこことマップの動画の案内の 2 か所
///   だけで、**下の広告バナーの近くには置かない**（ユーザーの判断））
class MenuSheet extends ConsumerStatefulWidget {
  const MenuSheet({
    required this.onClose,
    required this.onOpenCalendar,
    required this.onOpenRanking,
    required this.onOpenNotifications,
    this.initialView = rootView,
    super.key,
  });

  /// 開いた時に見せるビュー。
  static const rootView = 0;

  /// 広告を外す課金の画面。**マップの動画の案内の「広告を非表示」から直に開く**
  /// （ユーザーの指定。案内の中では買わせず、ここへ連れてくる）。
  static const removeAdsView = 3;

  final int initialView;

  final VoidCallback onClose;

  /// カレンダーを開く。**積むのは [AppShell] の仕事**（ランキングと同じ）。
  final VoidCallback onOpenCalendar;

  /// ランキングを開く。**積むのは [AppShell] の仕事**（どのタブに積むかを
  /// 知っているのはあちら）。
  final VoidCallback onOpenRanking;

  /// 通知設定を開く。**積むのは [AppShell] の仕事**（ランキングと同じ）。
  final VoidCallback onOpenNotifications;

  @override
  ConsumerState<MenuSheet> createState() => MenuSheetState();
}

class MenuSheetState extends ConsumerState<MenuSheet>
    with SingleTickerProviderStateMixin {
  /// 開閉と横送りの尺。web の `duration-200`。
  static const _anim = Duration(milliseconds: 200);

  /// 閉じる距離と速度。どちらかを満たせば閉じる。web の `DISMISS_PX` /
  /// `DISMISS_VELOCITY`。
  static const _dismissPx = 80.0;
  static const _dismissVelocity = 500.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _anim,
  );

  /// 0 = メニュー / 1 = 言語 / 2 = その他 / 3 = 広告を外す課金。
  late int _view = widget.initialView;

  /// 掴んで下げている量（px）。
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // 起動時に価格を取れなかった時（圏外など）のために、開くたびに取り直す
    // （取れていれば何もしない）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(removeAdsProvider.notifier).refreshProduct());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 閉じるアニメーションを見せてから畳む。
  Future<void> close() async {
    await _controller.reverse();
    if (mounted) widget.onClose();
  }

  /// [view] へ送る（開いたまま別の入口から呼ばれた時。`AppShell`）。
  void showView(int view) => setState(() => _view = view);

  /// 戻る操作を受けた。**2 階層目・3 階層目を開いていたらメニューへ戻すだけ**
  /// （web が履歴を 2 段積んでいるのと同じ考え方）。畳んだ時は true を返す。
  bool handleBack() {
    if (_view != 0) {
      setState(() => _view = 0);
      return true;
    }
    close();
    return true;
  }

  /// web の同じページを開く。
  ///
  /// **アプリ内ブラウザで開く**（`SFSafariViewController` / Chrome Custom Tabs）。
  /// 外部ブラウザに飛ばすとアプリに戻る導線が弱くなる。
  ///
  /// **URL は表示中のロケールに追従させる**（`/en/about/` など）。
  void _openOnWeb(String path) {
    final config = ref.read(appConfigProvider);
    final locale = ref.read(localeControllerProvider);
    launchUrl(
      Uri.parse(config.siteUrl(path, locale)),
      mode: LaunchMode.inAppBrowserView,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // **動きを減らす設定では動かさない。** この画面で一番動きの大きい UI
    // （花吹雪と同じ扱い）。開閉そのものは即座に反映される
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = reduceMotion
            ? (_controller.value > 0 ? 1.0 : 0.0)
            : Curves.easeOut.transform(_controller.value);
        return Stack(
          children: [
            // 暗幕。閉じ切るまでは残るので、ヒットテストは開いている間だけ
            Positioned.fill(
              child: IgnorePointer(
                ignoring: t == 0,
                child: GestureDetector(
                  onTap: close,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.5 * t),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FractionalTranslation(
                translation: Offset(0, 1 - t),
                child: Transform.translate(
                  offset: Offset(0, _drag),
                  child: _panel(colors),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _panel(AppColors colors) {
    final t = ref.watch(messagesProvider);

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      child: _dismissable(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_grip(colors), _viewport(colors, t)],
        ),
      ),
    );
  }

  /// **3 つのビューを横に並べ、表示中のぶんだけ見せる。**
  ///
  /// **高さは一番高いビューに固定する。** 表示中のビューに合わせて伸縮させると、
  /// 送るたびにシート全体が伸び縮みして落ち着かない。低いビューでは下に空きが
  /// 出るが、**動かないことを優先する**。
  Widget _viewport(AppColors colors, AppMessages t) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      // **画面を埋め尽くさない。** 端末の文字サイズを上げると行が伸びるので、
      // 上限を切って中で送れるようにする
      final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _view.toDouble()),
            duration: _anim,
            curve: Curves.easeOut,
            builder: (context, shift, _) => Stack(
              alignment: Alignment.topLeft,
              children: [
                for (final (index, view) in <Widget>[
                  _rootView(colors, t),
                  _langView(colors, t),
                  _otherView(colors, t),
                  _removeAdsView(colors, t),
                ].indexed)
                  Transform.translate(
                    offset: Offset((index - shift) * width, 0),
                    child: _scrollable(width, view),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );

  /// ビュー 1 枚。**中身が上限を超えた時だけ送れる**（`shrinkWrap` 相当の
  /// 振る舞いになるよう、高さは中身に合わせる）。
  Widget _scrollable(double width, Widget child) => SizedBox(
    width: width,
    child: SingleChildScrollView(
      // 中で送り切った先を親（一覧）へ渡さない
      physics: const ClampingScrollPhysics(),
      child: child,
    ),
  );

  /// 下に払って閉じる操作を受ける。
  ///
  /// **パネル全体で掴める。** 取っ手だけ（縦 20px）だと、閉じるのに細い帯を
  /// 狙わせることになる。web も `onVerticalDismiss(panel, …)` でパネル全体に
  /// 張っている。一覧が溢れている時はそちらのスクロールが先に取る。
  Widget _dismissable({required Widget child}) => GestureDetector(
    // **既定（`deferToChild`）にしない。** 「子が当たった位置でだけ自分も
    // 当たる」ので、取っ手のバーの周りの余白（当たる子が居ない）を払っても
    // 何も起きなくなる。**利用者は「掴め」と示している取っ手めがけて指を置く。**
    behavior: HitTestBehavior.opaque,
    onVerticalDragUpdate: (details) {
      final next = _drag + details.delta.dy;
      // 上へは動かさない（引き上げても伸びない）
      setState(() => _drag = next < 0 ? 0 : next);
    },
    onVerticalDragEnd: (details) {
      final velocity = details.primaryVelocity ?? 0;
      if (_drag > _dismissPx || velocity > _dismissVelocity) {
        close();
        return;
      }
      // 払い切らなければ戻す
      setState(() => _drag = 0);
    },
    child: child,
  );

  /// 掴めることを示す取っ手。
  Widget _grip(AppColors colors) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 6),
    child: Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: colors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  );

  /// 見出しの帯。**両方のビューに置く**（片方だけだと切り替えのたびに行が
  /// 上下にずれて見える）。
  Widget _heading(
    AppColors colors,
    String label, {
    Widget? leading,
    Widget? trailing,
  }) => Container(
    // **幅は器いっぱいに広げる。** 中身（見出しの文字）に縮むと、
    // 下の罫線が文字幅ぶんの短い線になる
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 48),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: colors.border)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        if (leading != null)
          Positioned(left: 0, top: 0, bottom: 0, child: leading),
        if (trailing != null)
          Positioned(right: 0, top: 0, bottom: 0, child: trailing),
      ],
    ),
  );

  Widget _rootView(AppColors colors, AppMessages t) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _heading(
        colors,
        t.navMenu,
        trailing: IconButton(
          onPressed: () => setState(() => _view = 2),
          icon: const Icon(Icons.more_vert, size: 20),
          color: colors.textSub,
          tooltip: t.menuOther,
        ),
      ),
      // **広告を外す課金は一番上に置く**（ユーザーの指定。下の方だと、送り切った
      // 先の行を押し間違える）。**ここでは買わせない** ―― 1 段深い画面で説明を
      // 読んでから買う・復元する（`_removeAdsView`）
      _removeAdsEntry(colors, t),
      _divider(colors),
      MenuListRow(
        label: t.navAbout,
        // web の `CmListRow icon="info"`
        icon: Icons.info_outline,
        external: true,
        onTap: () => _openOnWeb('/about/'),
      ),
      _divider(colors),
      // **並びはユーザーの指定**: とん速とは → カレンダー → ランキング →
      // 通知設定 → 外観 → 言語（web の `CoMenuSheet` はとん速とは・通知設定・
      // 外観・言語。web で下タブにあるカレンダー・ランキングをここへ詰めた）
      // **カレンダーもここに詰める**（web は下タブに置いているが、とん速の
      // アプリの下タブには入らない。ユーザーの指定）。**行ける月に予定が 1 件も
      // 無ければ行ごと出さない**（空の画面へ行ける入口を残さない。web の
      // `hasEvents` と同じく**画面に出る範囲で数える** —— `hasCalendarEventsInRange`）。
      // **取得できるまでは出しておく**（先に隠して後から現れると押し間違える。
      // ランキングの行と同じ判断）
      if (ref.watch(calendarEventsProvider).value case final events
          when events == null ||
              hasCalendarEventsInRange(events, todayInJst())) ...[
        MenuListRow(
          label: t.navCalendar,
          // web の `calendar_month`
          icon: Icons.calendar_month_outlined,
          onTap: widget.onOpenCalendar,
        ),
        _divider(colors),
      ],
      // **ランキングはここに詰める**（web は下タブに置いているが、とん速の
      // アプリの下タブには入らない。ユーザーの指定）。**中身が無い言語では行ごと
      // 出さない**（空の画面へ行ける入口を残さない。web の `hasRanking`）。
      // **取得できるまでは出しておく**（先に隠して後から現れると押し間違える。
      // gyumesy の下タブと同じ判断）
      if (ref.watch(rankingWindowsProvider).value case final resolved
          when resolved == null || hasAnyRanking(resolved)) ...[
        MenuListRow(
          label: t.navRanking,
          // web の `leaderboard`
          icon: Icons.leaderboard_outlined,
          onTap: widget.onOpenRanking,
        ),
        _divider(colors),
      ],
      MenuListRow(
        label: t.navNotifications,
        // web の `CmListRow icon="notifications"`
        icon: Icons.notifications_outlined,
        onTap: widget.onOpenNotifications,
      ),
      _divider(colors),
      MenuListRow(
        label: t.themeLabel,
        icon: Icons.contrast,
        trailing: const ThemeSwitch(),
      ),
      _divider(colors),
      MenuListRow(
        label: t.languageLabel,
        icon: Icons.language,
        value: ref.watch(localeControllerProvider).label,
        onTap: () => setState(() => _view = 1),
      ),
      // **最後の行の下にも線を引く。** 高さを一番高いビューに合わせている都合で
      // 下に空きが出るので、線が無いと一覧が途中で切れて見える
      _divider(colors),
    ],
  );

  /// メニューの一番上の「広告を非表示にする」。押すと購入の画面へ送る。
  /// 買ってある・保留中なら、それを値に出す（価格は購入の画面で出す）。
  Widget _removeAdsEntry(AppColors colors, AppMessages t) {
    final state = ref.watch(removeAdsProvider);
    return MenuListRow(
      label: t.removeAds,
      icon: Icons.block,
      value: state.purchased
          ? t.removeAdsPurchased
          : state.pending
          ? t.removeAdsPending
          : null,
      onTap: () => setState(() => _view = MenuSheet.removeAdsView),
    );
  }

  /// 広告を外す課金の画面（Issue #42）。**メニューの行の形にしない**（ユーザーの
  /// 指定）: 説明と購入のボタン、その下に小さな説明と復元のボタン。
  ///
  /// - **説明は買い切りであることを平易に書く**（ユーザーの指定）
  /// - **買ってある時は、押せないボタンに「購入済み」を出す**（もう一度買わせない）
  /// - **保留中は「保留中」を出して押せなくする**（二重に買わせない）
  /// - **価格はストアが返した表示価格**（取れるまでは出さない。アプリで金額を
  ///   持たない）。取れなくても押せる ―― 押せばもう一度ストアに聞き、繋がら
  ///   なければそう知らせる（押しても何も起きない形にしない）
  /// - **復元は常に置く**（App Store の審査でも必須）。**OS をまたいで引き継げない
  ///   ことも添える**（ユーザーの指定）
  /// - 購入・復元の途中は、押したボタンに回る印を出して両方とも押せなくする
  Widget _removeAdsView(AppColors colors, AppMessages t) {
    final state = ref.watch(removeAdsProvider);
    // **書体はテーマから引き継ぐ**（オンボーディングのボタンと同じ理由。素の
    // `TextStyle` を渡すと書体が落ちる）
    final label = Theme.of(context).textTheme.labelLarge;
    Widget spinner(Color color) => SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
    final price = state.price;
    final buyLabel = state.purchased
        ? t.removeAdsPurchased
        : state.pending
        ? t.removeAdsPending
        : price == null
        ? t.removeAdsBuy
        : '${t.removeAdsBuy}（$price）';
    final canBuy = !state.purchased && !state.pending && !state.busy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heading(colors, t.removeAds, leading: _backButton(colors, t)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.removeAdsLead,
                style: TextStyle(fontSize: 14, height: 1.8, color: colors.text),
              ),
              const SizedBox(height: 20),
              // **塗りの `primary` に白文字**（地の上の文字ではないので塗りのほう）
              FilledButton(
                onPressed: canBuy ? _buy : null,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  disabledBackgroundColor: colors.border,
                  disabledForegroundColor: colors.textSub,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: label?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: state.busy && _action == _RemoveAdsAction.buy
                    ? spinner(colors.onPrimary)
                    : Text(buyLabel),
              ),
              const SizedBox(height: 28),
              Text(
                t.removeAdsRestoreNote,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  color: colors.textSub,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: state.busy ? null : _restore,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.text,
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: label?.copyWith(fontSize: 14),
                  shape: const StadiumBorder(),
                ),
                child: state.busy && _action == _RemoveAdsAction.restore
                    ? spinner(colors.textSub)
                    : Text(t.restorePurchase),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// いま走っている操作（回る印をどちらの行に出すか）。
  _RemoveAdsAction? _action;

  Future<void> _buy() async {
    setState(() => _action = _RemoveAdsAction.buy);
    final result = await ref.read(removeAdsProvider.notifier).buy();
    _notify(result);
  }

  Future<void> _restore() async {
    setState(() => _action = _RemoveAdsAction.restore);
    final result = await ref.read(removeAdsProvider.notifier).restore();
    _notify(result);
  }

  /// 結果を画面の上端に短く出す（`AppToast`。通知設定の画面と同じ）。
  /// **メニューを閉じた後に返ってきた時は出さない**（結果は行の状態と、消えた
  /// 広告そのものに出ている）。
  void _notify(RemoveAdsResult result) {
    if (!mounted) return;
    setState(() => _action = null);
    final text = removeAdsResultText(ref.read(messagesProvider), result);
    if (text == null) return;
    AppToast.show(context, text.text, isError: text.isError);
  }

  /// 「その他」。**読む頻度が最も低いものだけを置く。**
  Widget _otherView(AppColors colors, AppMessages t) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _heading(colors, t.menuOther, leading: _backButton(colors, t)),
      // 並びは web のフッターと同じ（`LEGAL_PAGES`）。**特商法も置く** ――
      // 広告を外す課金（Issue #42）でアプリ内に有償の取引ができた（gyumesy は
      // 課金が無いので置いていない）
      MenuListRow(
        label: t.navTerms,
        icon: Icons.description_outlined,
        external: true,
        onTap: () => _openOnWeb('/legal/terms/'),
      ),
      _divider(colors),
      MenuListRow(
        label: t.navPrivacy,
        icon: Icons.lock_outline,
        external: true,
        onTap: () => _openOnWeb('/legal/privacy/'),
      ),
      _divider(colors),
      MenuListRow(
        label: t.navSct,
        icon: Icons.storefront_outlined,
        external: true,
        onTap: () => _openOnWeb('/legal/sct/'),
      ),
      _divider(colors),
      MenuListRow(
        label: t.menuLicenses,
        // 「利用規約」が書類の記号なので、こちらは著作権の記号にする
        icon: Icons.copyright_outlined,
        // 同梱書体（Klee One / Noto Sans JP）のぶんも `LicenseRegistry` に
        // 登録済み（`font_licenses.dart`）
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (context) => const LicensesPage()),
        ),
      ),
      _divider(colors),
      // **押せない行。** 表示するだけで、行き先は無い
      MenuListRow(
        label: t.menuVersion,
        // GitHub のリリース（タグ）と同じ形。版を指す記号として通じる
        icon: Icons.sell_outlined,
        value: ref.watch(appVersionProvider).value ?? '',
      ),
      _divider(colors),
    ],
  );

  /// 2 階層目・3 階層目の見出しに置く「戻る」。
  Widget _backButton(AppColors colors, AppMessages t) => TextButton.icon(
    onPressed: () => setState(() => _view = 0),
    icon: const Icon(Icons.arrow_back_ios, size: 16),
    label: Text(t.commonBack, style: const TextStyle(fontSize: 13)),
    style: TextButton.styleFrom(foregroundColor: colors.textSub),
  );

  Widget _langView(AppColors colors, AppMessages t) {
    final current = ref.watch(localeControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _heading(colors, t.languageLabel, leading: _backButton(colors, t)),
        // **言語名は自称表記で出す**（日本語 / English / 简体中文）。ISO コード
        // は開発者向けの記号で、英語話者・中国語話者には自分の言語だと伝わらない
        // （web の `CmLangOptions` と同じ）
        for (final locale in AppLocale.values) ...[
          MenuListRow(
            label: locale.label,
            bold: locale == current,
            chevron: false,
            trailing: locale == current
                ? Icon(Icons.check, size: 16, color: colors.primaryText)
                : null,
            onTap: locale == current
                ? null
                : () async {
                    await ref
                        .read(localeControllerProvider.notifier)
                        .set(locale);
                    if (mounted) setState(() => _view = 0);
                  },
          ),
          // **最後の項目の下にも線を引く。** 高さを高い方のビューに合わせて
          // いるので、こちらは下に空きが出る。線が無いと一覧が途中で切れて見える
          _divider(colors),
        ],
      ],
    );
  }

  Widget _divider(AppColors colors) =>
      Divider(height: 1, thickness: 1, color: colors.border);
}

enum _RemoveAdsAction { buy, restore }
