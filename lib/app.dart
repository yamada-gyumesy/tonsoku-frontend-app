import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/config/app_config_provider.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/router/app_router.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/core/theme/theme_mode_controller.dart';
import 'package:tonsoku/features/notifications/data/push_bootstrap.dart';
import 'package:tonsoku/features/notifications/domain/deep_link.dart';
import 'package:tonsoku/features/onboarding/presentation/onboarding_overlay.dart';
import 'package:tonsoku/features/shell/presentation/menu_screen_request.dart';

class TonsokuApp extends ConsumerStatefulWidget {
  const TonsokuApp({super.key});

  @override
  ConsumerState<TonsokuApp> createState() => _TonsokuAppState();
}

class _TonsokuAppState extends ConsumerState<TonsokuApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // **起動より前に積まれた行き先も拾う。** 終了状態から通知で開かれた時、
    // `getInitialMessage` は `runApp` の前に値を入れている（gyumesy と同じ）
    pushedLink.addListener(_openPushedLink);
    if (pushedLink.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPushedLink());
    }
    _listenAppLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pushedLink.removeListener(_openPushedLink);
    unawaited(_linkSub?.cancel());
    super.dispose();
  }

  /// ユニバーサルリンク / App Links。**通知のタップと同じ経路に合流させる。**
  /// gyumesy-frontend-app の `_listenAppLinks`（#90 で直した形）を写した。
  ///
  /// Safari や LINE で `ton-soku.com` のリンクを押した時にアプリが開く。
  /// **通知とは別の入口だが、行き先の決め方は同じ**（[deepLinkTarget]）ので、
  /// 分けて書くと片方だけ面が増えた時に食い違う。
  ///
  /// **行き先の正は [_syncLatestLink]（OS が最後に渡した 1 本）。**
  /// `uriLinkStream` は購読した時点で 1 本流してくるが、それは
  /// **`initialLink`＝最初に渡された 1 本**であって、最後の 1 本ではない
  /// （`AppLinksIosPlugin.swift` / `AppLinksPlugin.java`）。**普段は同じ値だが、
  /// 背面から踏まれた時にずれる**（gyumesy の実測）:
  ///
  /// - Android は、背面でプロセスを落とされた後にリンクを踏むと、
  ///   **アクティビティを作った時の intent（＝前に踏んだリンク）**で組み直し、
  ///   新しい 1 本は Dart が購読するより前の `onNewIntent` で届く。プラグインは
  ///   それを `latestLink` に入れるだけなので、購読時に流れてくるのは前の 1 本
  ///   （症状: **前に読んだ記事が開き、もう一度踏むと今度は正しく開く**）
  /// - iOS のプラグインはプロセスに 1 つで `initialLinkSent` を持ち回るので、
  ///   **エンジンを作り直すと 1 本も流れてこない**ことがある
  ///
  /// なので **購読直後の 1 本は「何か届いた」という合図としてだけ使い、値は
  /// 取り直す。** 2 本目以降は購読中に届いた新しい 1 本なので、そのまま使う
  /// （同じ URL を続けて踏んだ時も開き直せる）。
  void _listenAppLinks() {
    _linkSub = AppLinks().uriLinkStream.listen((uri) {
      if (_sawFirstLinkEvent) {
        _handleLink(uri.toString());
        return;
      }
      _sawFirstLinkEvent = true;
      unawaited(_syncLatestLink());
    });
    // **1 本も流れてこない場合があるので、こちらからも取りに行く**（上の doc）
    unawaited(_syncLatestLink());
  }

  StreamSubscription<Uri>? _linkSub;

  /// 購読直後の 1 本を受け取ったか（[_listenAppLinks] の doc）。
  bool _sawFirstLinkEvent = false;

  /// 最後に開いた URL。**復帰のたびに「新しい 1 本か」を見分けるためだけに持つ。**
  String? _handledLink;

  /// OS が最後に渡した 1 本を取り直し、まだ開いていなければ開く。
  ///
  /// **復帰のたびに呼ぶ。** 背面に居る間に届いた 1 本を取りこぼしても
  /// （プラグインは購読が切れている間に来たものを流し直さない）、次にアプリを
  /// 見た時には正しい面が出る。
  ///
  /// **開いた URL を覚えて、同じ値では動かない。** `getLatestLink` は
  /// **アプリが終わるまで同じ値を返し続ける**ので、覚えずに呼ぶと
  /// (1) ホーム画面から開き直しただけで前のリンクへ飛び、
  /// (2) 1 本を 2 回処理して、**アプリに画面が無い面ではブラウザが 2 枚開く**。
  Future<void> _syncLatestLink() async {
    final url = (await AppLinks().getLatestLink())?.toString();
    if (url == null || url.isEmpty || url == _handledLink) return;
    _handleLink(url);
  }

  /// 踏まれた 1 本を通知と同じ経路へ流す（[_handledLink] も進める）。
  void _handleLink(String url) {
    _handledLink = url;
    pushedLink.value = url;
  }

  /// 背面に居る間に届いた 1 本を取りこぼしていないか、復帰のたびに見る
  /// （[_syncLatestLink]）。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_syncLatestLink());
  }

  /// 外から渡された URL（通知のタップ・ユニバーサルリンク / App Links）を開く。
  /// **外から来た URL の受け口はここ 1 本**（gyumesy-frontend-app の
  /// `_openPushedLink` を写した）。入口ごとに行き先を決めると、片方だけ面が
  /// 増えた時に食い違う（gyumesy の #90 で一本化した理由）。
  ///
  /// **アプリに画面がある面はアプリ内で、無い面は外部ブラウザで開く**
  /// （[deepLinkTarget] の doc）。配信側に面が増えた時、アプリの更新を待たずに
  /// 読めるようにする。
  void _openPushedLink() {
    final url = pushedLink.value;
    if (url == null || url.isEmpty) return;
    // **一度で消す。** 残すと、次に画面が組み直された時にまた飛ぶ
    pushedLink.value = null;

    final siteHost = ref.read(appConfigProvider).siteHost;
    switch (deepLinkTarget(url, siteHost: siteHost)) {
      case RouteTarget(:final location):
        // **メニューから開いた画面を畳む**（理由は [requestFoldMenuScreens]）
        ref.read(appRouterProvider).go(location);
        requestFoldMenuScreens();
        return;
      // **積むのはシェル。** どのタブの中に積むか・既に開いていないかを
      // 知っているのはあちら（[requestOpenMenuScreen]）
      case final MenuScreenTarget target:
        requestOpenMenuScreen(target);
        return;
      // アプリに画面が無い面。下の外部ブラウザへ
      case null:
        break;
    }
    final uri = Uri.tryParse(url);
    // **http(s) 以外は開かない。** `inAppBrowserView` はスキームが http(s) で
    // ないと必ず投げる（`url_launcher_uri.dart`）。`unawaited` なので落ちはしない
    // が、**押しても何も起きない**状態になる。通知は外から来る値なので、
    // ここまで来ることがある
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) return;
    // **ここで出した URL が自分へ戻ってくる形にしないこと。** Android で
    // この ACTION_VIEW を受け取るのは「検証済みの App Links 持ち」＝自分自身
    // なので、**アプリが名乗っていて [deepLinkTarget] で開けない URL は、
    // 逃がすたびに戻ってきて際限なく往復する**（gyumesy の実測: 2000 回超の
    // 自己起動で ANR、端末の WindowManager ごと停止）。
    //
    // **戻りを実行時に見分ける手は無い**（戻ってきた 1 本と、利用者が同じ
    // リンクをもう一度踏んだ 1 本は URL が同じ）。防ぐのは
    // `AndroidManifest.xml` が**開ける面しか名乗らない**ことで、そのずれは
    // `deep_link_test.dart` が止める
    unawaited(launchUrl(uri, mode: LaunchMode.inAppBrowserView));
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: ref.watch(messagesProvider).appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // **書体はロケールで変わる**（日本語は Klee One。[AppTheme]）
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      themeMode: ref.watch(themeModeControllerProvider),
      // アプリの表示言語は設定で選ばれたものに固定する。端末設定は初回の推定に
      // しか使わない（LocaleController 参照）
      locale: locale.flutterLocale,
      supportedLocales: AppLocale.values.map((l) => l.flutterLocale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 初回だけオンボーディングを重ねる（重ねる形にした理由は
      // [OnboardingOverlay]。gyumesy と同じ置き場）
      // 戻る操作はルーターの受け口から先に取る（[OnboardingPage] の注記）
      builder: (context, child) => OnboardingOverlay(
        backButtonDispatcher: router.backButtonDispatcher,
        canPopUnderneath: router.canPop,
        child: child,
      ),
    );
  }
}
