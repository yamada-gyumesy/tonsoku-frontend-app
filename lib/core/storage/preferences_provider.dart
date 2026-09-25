import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 起動時に一度だけ解決する。`main()` で `overrideWithValue` して差し込む。
///
/// **保存済みのテーマ・言語を最初のフレームより前に読めるようにするための同期版。**
/// 非同期のまま起動すると、既定値で一瞬描いてから設定値に差し替わってちらつく。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);
