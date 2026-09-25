import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';

/// 表示テーマの選択。既定は OS 追従。
///
/// **保存するのは選ばれた 2 つ（ライト / ダーク）だけ。** 何も選んでいない間は
/// OS に追従する——端末側で夜間にダークにしている人が、何もしなくてもダークで
/// 読めることを優先している。web も操作としては 2 択（`CmThemeSwitch`）で、
/// 未保存の間は追従する。
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
