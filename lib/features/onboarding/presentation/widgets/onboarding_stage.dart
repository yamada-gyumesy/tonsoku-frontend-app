import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:tonsoku/core/theme/app_colors.dart';

/// オンボーディングの下地。gyumesy-frontend-app の同名のものを写し、色と絵を
/// とん速のものにした。
///
/// 地の上にブランドの 2 色の円を置き、絵を傾けて重ねる（gyumesy のストア画像と
/// 同じ考え方）。**色を足したり別の色を使ったりしない。**
///
/// **テーマで変えない。** 初回起動の 2 枚だけの画面で、ここだけはライトに
/// 固定する（gyumesy と同じ判断）。絵（web の OGP 画像・通知のサンプル）が
/// ライトの地で焼いてあるので、地だけ暗くすると絵の周りが明るく浮く。
///
/// ## gyumesy との違い
///
/// - **色は `AppColors.light` から取る**（とん速は配色の定義を
///   `app_colors.dart` の中だけに置く。CLAUDE.md「配色」）。gyumesy は
///   「テーマで変えない」ためにトークンを避けて値を直に書いているが、
///   **`AppColors.light` はライトの組そのもの**で、テーマ（`context.colors`）
///   を経由しないので、ダークでも追随しない
/// - 2 色は**赤（`primary`）と茶（`brown`）**。gyumesy のピンク / シアンに
///   当たるものを、とん速の配色トークンから選んだ（赤は OGP の縁取りの色）。
///   どちらも薄く（不透明度 0.10）敷くだけなので、字の読みやすさには関わらない
class OnboardingStage extends StatelessWidget {
  const OnboardingStage({required this.blobs, required this.child, super.key});

  /// 背景の円。**枚をまたいで流れるように置く**（gyumesy と同じ作り）。
  final List<StageBlob> blobs;
  final Widget child;

  static const _c = AppColors.light;

  /// 地。web の OGP 画像の地（`bg`）と同じ色で、絵の縁が地に溶ける。
  static final background = _c.bg;
  static final ink = _c.text;
  static final sub = _c.textSub;

  /// ボタン・進んだインジケーター。**塗り**の `primary`（白文字 7.20:1）。
  static final primary = _c.primary;

  /// 地の上に置く赤（インジケーター）。**塗りの [primary] を地の上に置かない**
  /// （CLAUDE.md「配色」。ライトでは同じ値だが、使い分けを崩さない）。
  static final primaryText = _c.primaryText;
  static final onPrimary = _c.onPrimary;
  static final brown = _c.brown;

  /// 進んでいないインジケーターの色。
  static final line = _c.border;

  /// 絵の面（カード・端末の画面）。
  static final surface = _c.surface;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (final b in blobs) b.build(context, c.biggest),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

/// 背景の円。位置と大きさは**画面の短辺に対する比**で持つ。
/// 端末の大小で崩れないようにするため。
class StageBlob {
  const StageBlob({
    required this.primary,
    required this.diameter,
    required this.left,
    required this.top,
    required this.opacity,
  });

  /// `true` なら赤（`primary`）、`false` なら茶（`brown`）。
  final bool primary;

  /// 画面の幅に対する直径の比。
  final double diameter;

  /// 画面の幅・高さに対する左上の比（負なら画面外へはみ出す）。
  final double left;
  final double top;
  final double opacity;

  Widget build(BuildContext context, Size size) {
    final d = size.width * diameter;
    return Positioned(
      left: size.width * left,
      top: size.height * top,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (primary ? OnboardingStage.primary : OnboardingStage.brown)
              .withValues(alpha: opacity),
        ),
      ),
    );
  }
}

/// 傾けた絵の札。**web の OGP 画像を 1 枚載せる**（1 枚目）。
///
/// gyumesy はここに端末のモック（黒い枠＋実スクリーンショット）を置いているが、
/// とん速はまだアプリのスクリーンショットを撮れていないので、**web が既に
/// とん速の意匠で焼いている OGP 画像**（カレンダー・クーポン。ロケールごと）を
/// 札として置く。スクリーンショットに差し替える時は [DeviceMock] を使う。
class TiltedCard extends StatelessWidget {
  const TiltedCard({
    required this.asset,
    required this.width,
    this.tiltDegrees = 0,
    super.key,
  });

  final String asset;
  final double width;
  final double tiltDegrees;

  /// web の OGP 画像の縦横比（1200 x 630）。
  static const aspect = 630 / 1200;

  @override
  Widget build(BuildContext context) {
    final radius = width * 0.04;
    // **`filterQuality` を `Transform` に渡さない・`RepaintBoundary` で包む**
    // 理由は [DeviceMock] と同じ（gyumesy が実機で踏んだ黒抜け）
    return RepaintBoundary(
      child: Transform.rotate(
        angle: tiltDegrees * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 32,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            borderRadius: BorderRadius.circular(radius),
            child: Image.asset(
              asset,
              width: width,
              height: width * aspect,
              fit: BoxFit.cover,
              // **縮小はミップマップで**（gyumesy と同じ。既定の `low` だと
              // 文字がざらつく）
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

/// 端末のモック。gyumesy のものを写した（中身を絵のファイルではなく
/// ウィジェットで受けるようにした）。
///
/// 黒い枠に切り欠きを描き、**下は切る**（全体を見せない）。
///
/// **中身は [screen] で受ける。** gyumesy は同梱の実スクリーンショット
/// （`assets/onboarding/home.webp`）を入れているが、とん速はまだ撮れて
/// いないので、2 枚目は画面を描いて入れている（`OnboardingPage` の doc）。
/// スクリーンショットを入れる時は `Image.asset` を渡せばよい。
class DeviceMock extends StatelessWidget {
  const DeviceMock({
    required this.screen,
    required this.width,
    this.tiltDegrees = 0,
    super.key,
  });

  final Widget screen;

  /// 端末の**画面**の幅（枠はこの外側に付く）。
  final double width;
  final double tiltDegrees;

  /// 画面の縦横比（iPhone 17 Pro の 1206 x 2622。gyumesy と同じ）。
  static const aspect = 2622 / 1206;

  @override
  Widget build(BuildContext context) {
    final pad = width * 0.017;
    final radius = width * 0.088;
    // **`filterQuality` を渡さない。** 渡すと `RenderTransform` が
    // `ImageFilterLayer` を張り、`alwaysNeedsCompositing` が立つ
    // （`proxy_box.dart` の `RenderTransform.paint`）。その内側で角丸の
    // クリップがさらに `saveLayer` を張るので、**オフスクリーンが 2 重**になる。
    // `PageView` の遷移中はそれ自体がクリップと変形の下に入り、**端末の絵が
    // 黒く抜けた**（gyumesy が実機で iOS / Android 両方）。
    //
    // **画質は落ちない。** 縮小の補間は `Image.asset` の `filterQuality` が、
    // 角丸の縁は下の `antiAliasWithSaveLayer` が持っている。渡さない時の
    // 回転は `pushTransform` で合成側が処理するので、最近傍にはならない
    //
    // **`RepaintBoundary` で包む。** 中身は完全に静止しているのに、
    // `PageView` の遷移中は毎フレーム描き直されていた（角丸の `saveLayer` ごと）。
    // 一度ラスタライズしておけば、遷移では合成側が動かすだけになる
    return RepaintBoundary(
      child: Transform.rotate(
        angle: tiltDegrees * math.pi / 180,
        child: Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(radius + pad),
            boxShadow: const [
              BoxShadow(
                color: Color(0x38000000),
                blurRadius: 40,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            // **`antiAliasWithSaveLayer` にする。** 既定の `antiAlias` だと
            // 回転した角丸の縁にジャギーが出る（クリップと中身が別レイヤーで
            // 合成されないため）
            clipBehavior: Clip.antiAliasWithSaveLayer,
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              width: width,
              height: width * aspect,
              child: Stack(
                children: [
                  Positioned.fill(child: screen),
                  // Dynamic Island
                  Positioned(
                    top: width * 0.038,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: width * 0.185,
                        height: width * 0.045,
                        decoration: BoxDecoration(
                          color: const Color(0xFF05090D),
                          borderRadius: BorderRadius.circular(width * 0.03),
                        ),
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
