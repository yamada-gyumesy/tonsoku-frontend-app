import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/router/app_router.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/core/theme/theme_mode_controller.dart';

class TonsokuApp extends ConsumerWidget {
  const TonsokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
