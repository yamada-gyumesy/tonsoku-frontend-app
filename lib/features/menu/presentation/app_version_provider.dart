import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 表示用のアプリバージョン（`1.0.0`）。
///
/// **入っている実物から読む。** `pubspec.yaml` の値を焼き込むと、ストア用に
/// ビルド番号だけ上げた時に画面の表示と食い違う。
///
/// **ビルド番号は出さない。** 読む人にとって意味があるのは公開されている版で、
/// ビルド番号は同じ版の中で何度も変わる（審査の出し直しなど）。出すと「同じ
/// 1.0.0 なのに数字が違う」と読まれる。
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});
