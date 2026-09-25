import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/licenses/font_licenses.dart';

/// 同梱書体のライセンスが**実際に読めること**を確かめる（gyumesy と同じ）。
///
/// **これが落ちない限り、本番の collector は誰も動かさない。** 収集側は読めない
/// 時に黙って 1 件落とす（他の 200 件以上を巻き添えにしないため）ので、
/// アセット名を変えても画面上は「その書体が無い」だけになり、気づけない。
/// SIL Open Font License は帰属表示を求めるので、消えたままは出荷できない。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(LicenseRegistry.reset);
  tearDown(LicenseRegistry.reset);

  test('同梱書体のライセンスが全部読めて、登録される', () async {
    registerFontLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    for (final MapEntry(key: name, value: asset) in fontLicenseAssets.entries) {
      final font = entries.where((e) => e.packages.contains(name));
      expect(font, isNotEmpty, reason: '$asset が読めていない（名前を変えた？）');
      // 中身が空のファイルに差し替わっても気づけるようにする
      expect(
        font.first.paragraphs.map((p) => p.text).join(),
        contains('SIL OPEN FONT LICENSE'),
        reason: name,
      );
    }
  });
}
