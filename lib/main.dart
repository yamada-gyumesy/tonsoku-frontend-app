import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tonsoku/app.dart';
import 'package:tonsoku/core/storage/json_cache.dart';
import 'package:tonsoku/core/storage/preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 保存済みのテーマ・言語を反映してから最初のフレームを描く。非同期のまま
  // 起動すると、既定値で一瞬描いてから設定値に差し替わってちらつく
  final prefs = await SharedPreferences.getInstance();
  final cache = await JsonCache.open();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        jsonCacheProvider.overrideWithValue(cache),
      ],
      child: const TonsokuApp(),
    ),
  );
}
