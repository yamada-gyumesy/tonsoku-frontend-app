import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';

/// 表示言語。初回は端末の言語設定から推定し、以降は選ばれたものを永続化する。
///
/// **`Accept-Language` 相当の自動判定は初回だけ。** Web も「利用者が明示的に
/// 選んだ時だけ保存する」方針を取っており、一度選ばれた言語を端末設定で
/// 上書きしない。
class LocaleController extends Notifier<AppLocale> {
  static const _key = 'app_locale';

  /// 動作確認用の上書き（`--dart-define=LOCALE=en`）。
  ///
  /// 表示言語の切替 UI はメニュー（別 Issue）で入るまで無いので、それまで
  /// en / zh の画面を実機で見る手段としてここに置く。**保存済みの選択より
  /// 優先する**ので、確認以外では渡さないこと。
  static const _override = String.fromEnvironment('LOCALE');

  @override
  AppLocale build() {
    final forced = AppLocale.fromCode(_override.isEmpty ? null : _override);
    if (forced != null) return forced;

    final saved = AppLocale.fromCode(
      ref.watch(sharedPreferencesProvider).getString(_key),
    );
    if (saved != null) return saved;
    return AppLocale.fromSystem(PlatformDispatcher.instance.locales);
  }

  Future<void> set(AppLocale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(_key, locale.code);
  }
}

final localeControllerProvider = NotifierProvider<LocaleController, AppLocale>(
  LocaleController.new,
);

final messagesProvider = Provider<AppMessages>(
  (ref) => AppMessages.of(ref.watch(localeControllerProvider)),
);
