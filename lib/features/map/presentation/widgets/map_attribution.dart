import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/theme/app_theme.dart';

/// 地図データの帰属表記。**左下に常に出す「© OpenStreetMap」**（ユーザーの判断）。
/// 押すと著作権のページを開く。
///
/// - **「contributors」は付けない**（ユーザーの判断）。OpenStreetMap 財団の
///   帰属表示の指針（https://osmfoundation.org/wiki/Licence/Attribution_Guidelines ）
///   は「© OpenStreetMap」を著作権のページへつないで出す形を認めている
/// - 地図を塞がないよう、地は薄く（面色の 55%）
/// - メニューのライセンス一覧にも載せてある（`registerMapDataLicense`）
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  static final copyright = Uri.parse('https://www.openstreetmap.org/copyright');

  /// 固有の表記なので訳さない。
  static const text = '© OpenStreetMap';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      link: true,
      child: GestureDetector(
        onTap: () => launchUrl(copyright, mode: LaunchMode.inAppBrowserView),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: MapPalette.of(colors).panel.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: colors.textSub,
              // 欧文の表記なので欧文の書体で（日本語の画面でも Klee One にしない）
              fontFamily: AppTheme.defaultFontFamily,
            ),
          ),
        ),
      ),
    );
  }
}
