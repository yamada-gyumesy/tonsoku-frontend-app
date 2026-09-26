import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/core/theme/app_theme.dart';
import 'package:tonsoku/core/utils/article_date.dart';

/// 通知の見本 1 枚（通知設定の横に流す 5 枚と、オンボーディングの 1 枚）。
///
/// ## 画像ではなくウィジェットで描く
///
/// **以前は web が焼いた WebP（`public/images/notifications/`）を写して
/// 出していた**が、字が絵に焼き込まれているので、**英語・中国語の画面にも
/// 日本語の通知が出ていた**（ユーザーの決定「英語・中国語の画面に日本語を
/// 1 文字も残さない」）。web は同じ絵を全ロケールで出しているが、アプリは
/// 文言を [AppMessages] から引いて表示言語で描く。
///
/// **組版は web の見本と同じ**（`tonsoku-frontend-web/scripts/notification-samples/
/// light1.html`。gyumesy の組版の実測値）。450 x 135 の枠に同じ座標で置き、
/// [FittedBox] で幅に合わせて縮める ―― 字の大きさも一緒に縮むので、絵だった
/// 時と同じ見え方になる。
///
/// - **アイコンに白い円を敷かない**（web の `docs/notification-samples.md`。
///   とん速のアイコンはそれ自体が赤い円なので、白の上に縮めると白い輪が付く）。
///   36 の丸にロゴ（web の `public/icon.svg` と同じ `assets/brand/logo.svg`）を丸ごと敷く
/// - **色は OS の通知の色**（[NotificationSamplePalette]。とん速の配色に置き換えない）
/// - **書体はロケールによらず Noto Sans JP**（web の見本と同じ）。日本語の画面の
///   Klee One で描くと、端末に出る通知と別物に見える
class NotificationSample extends StatelessWidget {
  const NotificationSample({
    required this.appName,
    required this.separator,
    required this.time,
    required this.text,
    required this.brightness,
    super.key,
  });

  /// そのロケールの見本を並びどおりに作る。
  ///
  /// [brightness] は**呼び出し側が決める**。通知設定はテーマに合わせ、
  /// オンボーディングはライトに固定する（地がテーマで変わらないので）。
  static List<NotificationSample> all(
    AppMessages t,
    AppLocale locale,
    Brightness brightness,
  ) => [
    for (final (i, text) in t.notificationsSamples.indexed)
      NotificationSample(
        appName: t.appName,
        separator: t.notificationsSampleSeparator,
        time: formatElapsed(ages[i % ages.length], locale),
        text: text,
        brightness: brightness,
      ),
  ];

  /// 見本の時刻（web の見本の「たった今」「5分前」「3分前」「10分前」「1時間前」）。
  /// **表記は記事の相対表記と同じもの**（[formatElapsed]）を通す。
  static const ages = [
    Duration.zero,
    Duration(minutes: 5),
    Duration(minutes: 3),
    Duration(minutes: 10),
    Duration(hours: 1),
  ];

  /// 組版の枠（web の見本の `450x135`）。
  static const _width = 450.0;
  static const _height = 135.0;

  /// 縦横比。**横に流す時の高さはこれで決める**（`AutoSlider`）。
  static const aspectRatio = _width / _height;

  /// 本文の右端。web の `.txt` の `left:70px; width:360px` から（右に 20 空く）。
  static const _textLeft = 70.0;
  static const _textRight = _width - _textLeft - 360;

  final String appName;
  final String separator;
  final String time;
  final NotificationSampleText text;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final palette = NotificationSamplePalette.of(brightness);
    // web の `line-height` は行の上下に均等に余白を振る。Flutter の既定
    // （proportional）だと字が枠の中で上下にずれ、web の座標と合わない
    const base = TextStyle(
      fontFamily: AppTheme.defaultFontFamily,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: FittedBox(
        child: SizedBox(
          width: _width,
          height: _height,
          child: MergeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 21,
                    top: 21,
                    child: ClipOval(
                      child: SvgPicture.asset(
                        'assets/brand/logo.svg',
                        width: 36,
                        height: 36,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  Positioned(
                    left: _textLeft,
                    right: _textRight,
                    top: 22,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: appName),
                          // web の `<span style="opacity:.7">`
                          TextSpan(
                            text: '$separator$time',
                            style: TextStyle(
                              color: palette.appName.withValues(alpha: .7),
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: base.copyWith(
                        fontSize: 15,
                        height: 1,
                        color: palette.appName,
                      ),
                    ),
                  ),
                  Positioned(
                    left: _textLeft,
                    right: _textRight,
                    top: 52,
                    child: Text(
                      text.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: base.copyWith(
                        fontSize: 17,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                      ),
                    ),
                  ),
                  Positioned(
                    left: _textLeft,
                    right: _textRight,
                    top: 86,
                    // **1 行で切る**（web の `white-space: nowrap`）。文言は
                    // 収まる長さにしてある（[AppMessages.notificationsSamples]）。
                    // 省略記号は、訳を足して溢れた時に黙って途切れないための保険
                    child: Text(
                      text.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: base.copyWith(
                        fontSize: 17,
                        height: 1.2,
                        color: palette.body,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
