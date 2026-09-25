import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 同梱書体（Klee One / Noto Sans JP）のライセンスを [LicenseRegistry] へ登録する
/// （gyumesy-frontend-app の `font_licenses.dart` を写し、書体を 2 つにした）。
///
/// Flutter 標準の収集は **Dart パッケージのみ**列挙し、`pubspec.yaml` の
/// `fonts:` で同梱した書体は含まれない。SIL Open Font License は帰属表示を
/// 求めるので、ここで補う。
///
/// **とん速は 2 書体を同梱している**（日本語は Klee One、英語・中国語は
/// Noto Sans JP。`tool/build_fonts.py`）。**どちらも OFL で、どちらも表示が要る。**
/// 書体を足した時はここにも足す。
const fontLicenseAssets = <String, String>{
  'Klee One': 'assets/licenses/klee-one-ofl.txt',
  'Noto Sans JP': 'assets/licenses/noto-sans-jp-ofl.txt',
};

void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: name, value: asset) in fontLicenseAssets.entries) {
      // **読めなくても投げない。** [LicenseRegistry.licenses] は全 collector を
      // 1 本の Stream に束ねるので、ここで例外を出すと**他の 200 件以上が
      // まとめて消える**（同梱物の著作権表示が全部無くなる）。1 件落ちるほうが
      // まだ小さい。
      //
      // **黙って落ちたままにしないのはテストの仕事。** アセット名を変えたら
      // `font_licenses_test.dart` が落ちる。
      final String text;
      try {
        text = await rootBundle.loadString(asset);
      } on Object {
        continue;
      }
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
}
