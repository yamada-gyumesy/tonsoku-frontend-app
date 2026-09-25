import 'dart:async';

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
import 'package:tonsoku/features/shell/presentation/menu_screen_request.dart';

class TonsokuApp extends ConsumerStatefulWidget {
  const TonsokuApp({super.key});

  @override
  ConsumerState<TonsokuApp> createState() => _TonsokuAppState();
}

class _TonsokuAppState extends ConsumerState<TonsokuApp> {
  @override
  void initState() {
    super.initState();
    // **起動より前に積まれた行き先も拾う。** 終了状態から通知で開かれた時、
    // `getInitialMessage` は `runApp` の前に値を入れている（gyumesy と同じ）
    pushedLink.addListener(_openPushedLink);
    if (pushedLink.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPushedLink());
    }
  }

  @override
  void dispose() {
    pushedLink.removeListener(_openPushedLink);
    super.dispose();
  }

  /// 通知から渡された URL を開く。**外から来た URL の受け口はここ 1 本**
  /// （gyumesy-frontend-app の `_openPushedLink` を写した）。
  ///
  /// **ユニバーサルリンク / App Links（リリース整備の Issue #9）も
  /// [pushedLink] へ積んでここに合流させること。** 入口ごとに行き先を決めると、
  /// 片方だけ面が増えた時に食い違う（gyumesy の #90 で一本化した理由）。
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
    // **App Links を入れる時（#9）は、ここで出した URL が自分へ戻ってくる形に
    // しないこと。** Android でこの ACTION_VIEW を受け取るのは「検証済みの
    // App Links 持ち」＝自分自身なので、**アプリが名乗っていて [deepLinkTarget]
    // で開けない URL は、逃がすたびに戻ってきて際限なく往復する**（gyumesy の
    // 実測: 2000 回超の自己起動で ANR）。防ぐのは `AndroidManifest.xml` が
    // **開ける面しか名乗らない**ことで、そのずれは `deep_link_test.dart` が止める
    unawaited(launchUrl(uri, mode: LaunchMode.inAppBrowserView));
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);

    return MaterialApp.router(
      title: ref.watch(messagesProvider).appName,
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(appRouterProvider),
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
    );
  }
}
