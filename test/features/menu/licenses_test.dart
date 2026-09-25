import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/licenses/dev_only_packages.dart';
import 'package:tonsoku/features/menu/presentation/licenses_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ライセンス表記に載せてよいのは、**アプリに同梱されるものだけ**。
///
/// Flutter が集める `NOTICES` は生成器（build_runner・freezed など）まで含む。
/// ビルド時にしか動かず配布物に入らないので、載せると事実と違う。
void main() {
  setUp(LicenseRegistry.reset);
  tearDown(LicenseRegistry.reset);

  test('生成器のライセンスは載せない', () async {
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(['dio'], 'dio のライセンス');
      // build_runner は同梱されない（`dev_only_packages.dart`）
      yield const LicenseEntryWithLineBreaks([
        'build_runner',
      ], 'build_runner のライセンス');
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final packages = await container.read(bundledLicensesProvider.future);

    expect(packages.map((p) => p.name), ['dio']);
  });

  test('除外リストに生成器が入っている（生成が空振りしていない）', () {
    // `tool/build_licenses.py` が空のリストを吐いても気づけるようにする
    expect(devOnlyPackages, contains('build_runner'));
    expect(devOnlyPackages, contains('freezed'));
    expect(devOnlyPackages, contains('json_serializable'));
    // 実行時に載るものが紛れ込んでいない
    expect(devOnlyPackages, isNot(contains('dio')));
    expect(devOnlyPackages, isNot(contains('video_player')));
  });

  test('同じパッケージのライセンスはまとめ、名前順に並べる', () async {
    LicenseRegistry.addLicense(() async* {
      yield const LicenseEntryWithLineBreaks(['zebra'], 'z');
      yield const LicenseEntryWithLineBreaks(['apple'], 'a1');
      yield const LicenseEntryWithLineBreaks(['apple'], 'a2');
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final packages = await container.read(bundledLicensesProvider.future);

    expect(packages.map((p) => p.name), ['apple', 'zebra']);
    expect(packages.first.licenses.length, 2);
  });
}
