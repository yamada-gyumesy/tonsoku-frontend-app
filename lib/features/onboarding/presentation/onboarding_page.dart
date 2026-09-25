import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/analytics/screen_path.dart';
import 'package:tonsoku/core/analytics/track_screen.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/notifications/presentation/notification_settings_controller.dart';
import 'package:tonsoku/features/onboarding/presentation/widgets/onboarding_stage.dart';
import 'package:tonsoku/shared/models/category.dart';

/// 初回起動の 2 画面。**web には無い（アプリ独自）。** gyumesy-frontend-app の
/// 同名のものを写した（振る舞いはそのまま。文言・色・絵をとん速のものにした）。
///
/// **OS の通知許可をいきなり出さない。** 何が届くのかを 2 枚目で見せてから
/// 求める。**一度拒否されると設定アプリへ行かない限り戻せない**ので、初回の
/// 出し方が効く。
///
/// **許可しなくても使える。** 「あとで」で閉じられる。
///
/// **画面ごとライト固定。** 絵はライトの地で焼いてあるので（[OnboardingStage]）、
/// 地色・インジケーター・ボタンだけテーマに追随すると、明るい絵の上下だけが
/// 暗い、という分断した見え方になる。**色はすべて [OnboardingStage] から取る**
/// （テーマのトークンを混ぜない）。
///
/// ## 絵（gyumesy との違い）
///
/// gyumesy はアプリの実スクリーンショット（`home.webp` / `coupon.webp`）を
/// 端末の枠に入れている。**とん速はまだ撮れていない**（シミュレーターを
/// 使えなかった）ので、当面は次のもので組んでいる。
///
/// - 1 枚目 … **web の OGP 画像**（カレンダー・クーポン。`assets/onboarding/`。
///   web の `public/ogp-{calendar,coupon}{,.en,.zh}.png` を幅 900 の WebP に
///   縮めたもの）。とん速の意匠で焼かれていて、ロケールごとにある
/// - 2 枚目 … 端末の枠に**描いた画面**（地とロゴだけ）を入れ、通知の
///   サンプルを重ねる
///
/// **スクリーンショットが撮れたら差し替える**（[DeviceMock] に `Image.asset` を
/// 渡す。gyumesy と同じ 1206 x 2622 で撮り、幅 900 の WebP に縮める）。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({
    required this.onDone,
    this.backButtonDispatcher,
    super.key,
  });

  final VoidCallback onDone;

  /// ルーターの戻るの受け口（`GoRouter.backButtonDispatcher`）。**この子になって
  /// 戻る操作を先に取る**（`_OnboardingPageState._back`）。null なら取らない
  /// （テストで単体に置く時）。
  final BackButtonDispatcher? backButtonDispatcher;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;
  bool _busy = false;

  /// 通知のサンプル。**通知設定の画面と同じもの**（web がとん速のぶんを焼いた絵）。
  ///
  /// **1 枚だけ出す。** 横に流すと位置が定まらず、何が届くのかを読む前に
  /// 次へ行ってしまう（gyumesy と同じ）。中身は記事の通知として一番よくある
  /// 「メニュー」のもの。
  ///
  /// **ライト版で固定する。** 重ねる先は明るい端末の画面なので、ダーク版
  /// （黒の半透明カード）を載せると灰色の染みになって字が読めない。
  /// 通知設定の画面と違い、ここは地がテーマで変わらない
  static const _sample = 'assets/notifications/notification-sample-1.webp';

  /// **戻る操作は、ルーターの戻るの受け口で先に取る**（[_onBack]）。
  ///
  /// オンボーディングは `MaterialApp.router` の `builder:` で本体に重ねてあり、
  /// **ナビゲータの外**に居る。`PopScope` は `ModalRoute` に登録して効くので
  /// ここでは効かず、`BackButtonListener` も `builder:` がルーターの外なので
  /// 届かない。そのまま戻るを押すと、ルートならアプリを抜け、ディープリンクで
  /// 記事を開いていれば**下に隠れた記事だけが pop される**（レビューで判明。
  /// gyumesy も同じ置き方で同じ穴がある）。**ルーター自身の
  /// `BackButtonDispatcher` の子になって優先を取れば**、置き場に関係なく
  /// 最初に呼ばれる
  ChildBackButtonDispatcher? _back;

  @override
  void initState() {
    super.initState();
    if (widget.backButtonDispatcher case final parent?) {
      _back = ChildBackButtonDispatcher(parent)
        ..addCallback(_onBack)
        ..takePriority();
    }
  }

  @override
  void dispose() {
    if (_back case final back?) {
      back
        ..removeCallback(_onBack)
        ..parent.forget(back);
    }
    _controller.dispose();
    super.dispose();
  }

  /// **2 枚目で戻ったら 1 枚目へ返す。** 横取りしないとオンボーディングごと
  /// アプリが終わり、見終わっていないので**次の起動でまた最初から**出る
  /// （利用者は「閉じた」つもりなのに戻ってくる）。
  ///
  /// **1 枚目での戻るはアプリを抜ける**（ここが最初の画面なので、終わるのが
  /// 自然）。ルーターへ通すと、下にディープリンクの記事がある時にそれだけが
  /// pop されるので、ルーターへは渡さない。
  Future<bool> _onBack() async {
    if (_page == 0) {
      await SystemNavigator.pop();
      return true;
    }
    // 送りの完了は待たない（受け口は「処理した」をすぐ返せばよい）
    unawaited(
      _controller.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    );
    return true;
  }

  /// 通知を入れて閉じる。
  ///
  /// **購読の完了を待たない。** iOS は許可の直後にまだ APNs トークンが無く、
  /// `subscribeToTopic` が長く返らないことがある。待っていると、OS のダイアログ
  /// から戻ってきた画面で**「通知を有効にする」が押せないまま**になり、どうすれば
  /// よいか分からなくなる（gyumesy が実機で踏んだ）。**ダイアログが閉じた時点で
  /// 閉じる。**
  ///
  /// 購読はそのまま裏で続く。失敗しても通知設定の画面から貼り直せる。
  ///
  /// **閉じるのはダイアログが閉じた後。** 閉じると広告の SDK が始まって
  /// ATT のダイアログが出る（`waitForOnboarding`）ので、先に閉じると
  /// 通知の許可と ATT が重なる。
  Future<void> _allow() async {
    if (_busy) return;
    setState(() => _busy = true);
    // **先に掴んでおく。** 閉じたあとも購読は続くが、`ref` は破棄後に使えない
    final controller = ref.read(
      notificationSettingsControllerProvider.notifier,
    );
    final categoryIds = await _categoryIds();
    if (!mounted) return;
    // **初期購読は全カテゴリ。** まず届く状態にして、多いと感じたら
    // メニューの通知設定で減らしてもらう（gyumesy と同じ）。
    unawaited(
      controller.enableMaster(
        categoryIds,
        onPermissionDecided: () {
          if (!mounted) return;
          setState(() => _busy = false);
          widget.onDone();
        },
      ),
    );
  }

  /// 読み込めているカテゴリ。**`build` で `watch` している**（`read` するだけ
  /// だと、その場から購読が始まって空になる）。
  var _categories = const <Category>[];

  /// 購読するカテゴリ。**まだ届いていなければ待つ。**
  ///
  /// `watch` していても「押された時点で揃っている」とは限らない ——
  /// **初回起動はキャッシュが無いので必ず通信が要り**、圏外・低速では
  /// まだ空。そのまま進むと **OS の許可だけ取れて購読が 0 件**になる
  /// （gyumesy の 79d2ce4 で直した不具合。繰り返さない）。
  ///
  /// **待ちきれなければ空で進む。** 許可そのものは利用者の意思なので取り消さ
  /// ない。空は保存されない（[NotificationSettingsController.enableMaster]。
  /// 焼かれた `{}` も未設定として読む `NotificationStore.readTopics`）ので、
  /// カテゴリが届いた後に通知設定から貼り直せる。
  Future<List<String>> _categoryIds() async {
    if (_categories.isNotEmpty) return [for (final c in _categories) c.slug];
    try {
      // **無期限に待たない。** 押したのに OS のダイアログが出ないまま
      // 固まって見えるほうが困る
      final categories = await ref
          .read(categoriesProvider.future)
          .timeout(const Duration(seconds: 5));
      return [for (final c in categories) c.slug];
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(messagesProvider);
    final locale = ref.watch(localeControllerProvider);
    // **ここで購読しておく。** 押された時に読むだけだと、その場から取得が
    // 始まって空になり、**1 つも購読されないまま「許可した」状態になる**
    _categories = ref.watch(categoriesProvider).value ?? const <Category>[];

    return TrackScreen(
      // **web に対応が無いので [ScreenPath.appOnly]**（既存のレポートを汚さない）
      screen: ScreenPath.appOnly(
        locale,
        t,
        name: _page == 0 ? 'onboarding/intro' : 'onboarding/notifications',
        title: _page == 0 ? t.onboardingIntroTitle : t.onboardingNotifyTitle,
      ),
      // 戻る操作は [_onBack]（`PopScope` はここでは効かない。[_back] の注記）
      //
      // **ステータスバーの字も暗くする。** 地をライトに固定するので、OS の
      // ダークに合わせて白いままだと時刻とアンテナが読めなくなる
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: OnboardingStage.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          // **テーマに追随させない。** 絵はライトの地で焼いてあるので、
          // 地だけ暗いと絵の上下に濃い帯が出て分断して見える
          backgroundColor: OnboardingStage.background,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [
                      _Intro(t: t, locale: locale),
                      _Notify(t: t, sample: _sample),
                    ],
                  ),
                ),
                // **上下に余白を取る。** 端末のモックが下端まで伸びるので、
                // 詰めると絵に食い込んで読めない
                const SizedBox(height: 24),
                _Dots(count: 2, current: _page),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  // **どちらの枚でも同じ高さを取る。** 1 枚目だけボタンが
                  // 1 段だと、上の絵の高さが枚をまたいで変わって落ち着かない
                  child: Column(
                    children: [
                      _Primary(
                        label: _page == 0
                            ? t.onboardingNext
                            : t.onboardingAllow,
                        onPressed: _busy
                            ? null
                            : _page == 0
                            ? () => _controller.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              )
                            : _allow,
                      ),
                      const SizedBox(height: 8),
                      // **許可しなくても使える。** 同じ強さで並べない。
                      // 1 枚目では場所だけ取って出さない
                      Visibility(
                        visible: _page == 1,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: TextButton(
                          onPressed: _busy ? null : widget.onDone,
                          style: TextButton.styleFrom(
                            foregroundColor: OnboardingStage.sub,
                            // **高さを詰める。** 既定は 48 あり、1 枚目で
                            // 場所だけ取ると下がぽっかり空いて見える
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                          ),
                          child: Text(t.onboardingSkip),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.t, required this.locale});

  final AppMessages t;
  final AppLocale locale;

  /// web の OGP 画像。**ロケールごとに別の絵**（見出しの文字が焼き込まれている）。
  /// 日本語は接尾辞無し（web の `ogp-coupon.png` と `ogp-coupon.en.png` の関係）。
  String _card(String name) => locale.isDefault
      ? 'assets/onboarding/$name.webp'
      : 'assets/onboarding/$name-${locale.code}.webp';

  @override
  Widget build(BuildContext context) => OnboardingStage(
    // gyumesy と同じ流れ。1 枚目は左上に赤・右下に茶
    blobs: const [
      StageBlob(
        primary: true,
        diameter: .95,
        left: -.24,
        top: -.10,
        opacity: .10,
      ),
      StageBlob(
        primary: false,
        diameter: .70,
        left: .62,
        top: .62,
        opacity: .10,
      ),
    ],
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: 28,
          right: 28,
          top: 48,
          child: _Copy(
            title: t.onboardingIntroTitle,
            body: t.onboardingIntroBody,
          ),
        ),
        // **コピーの下から始める。** 被せると本文が読めない。
        // 2 枚は互い違いに傾けて重ねる（gyumesy の端末 2 台と同じ置き方）
        Positioned(
          left: -16,
          top: 300,
          child: TiltedCard(
            asset: _card('calendar'),
            width: 300,
            tiltDegrees: -8,
          ),
        ),
        Positioned(
          right: -20,
          top: 430,
          child: TiltedCard(asset: _card('coupon'), width: 300, tiltDegrees: 6),
        ),
      ],
    ),
  );
}

class _Notify extends StatelessWidget {
  const _Notify({required this.t, required this.sample});

  final AppMessages t;

  /// 通知サンプル。**位置がずれないよう、端末の上に
  /// 実寸で重ねる**（横スライドで流さない）。
  final String sample;

  @override
  Widget build(BuildContext context) => OnboardingStage(
    // 1 枚目からの続き。左下に赤・右上に茶
    blobs: const [
      StageBlob(
        primary: false,
        diameter: .60,
        left: .66,
        top: -.08,
        opacity: .10,
      ),
      StageBlob(
        primary: true,
        diameter: .92,
        left: -.28,
        top: .66,
        opacity: .10,
      ),
    ],
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: 28,
          right: 28,
          top: 48,
          child: _Copy(
            title: t.onboardingNotifyTitle,
            body: t.onboardingNotifyBody,
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 250,
          child: Center(child: DeviceMock(screen: _LockScreen(), width: 300)),
        ),
        // **通知は端末より少しだけ広く、左右にはみ出す**（実物の通知と同じ出方。
        // gyumesy と同じ）
        Positioned(
          left: 34,
          right: 34,
          top: 336,
          child: Image.asset(sample, fit: BoxFit.fitWidth),
        ),
      ],
    ),
  );
}

/// 端末の画面の代わりに描く面。**地とロゴだけ**（`OnboardingPage` の doc の
/// 「絵」）。通知のサンプルを載せる先なので、字や絵を入れて読み合いにしない。
class _LockScreen extends StatelessWidget {
  const _LockScreen();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: OnboardingStage.surface,
    child: Align(
      // 通知のサンプル（端末の上寄り）と重ならない高さ
      alignment: const Alignment(0, 0.15),
      child: FractionallySizedBox(
        widthFactor: 0.3,
        // ヘッダーのロゴと同じ絵（web の `public/icon.svg`）
        child: SvgPicture.asset('assets/brand/logo.svg'),
      ),
    ),
  );
}

/// 見出しと本文。**gyumesy のストア画像と同じ組み方**（左寄せ・太字＋細字）。
class _Copy extends StatelessWidget {
  const _Copy({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 27,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: OnboardingStage.ink,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        body,
        style: TextStyle(fontSize: 14, height: 1.7, color: OnboardingStage.sub),
      ),
    ],
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == current
                  ? OnboardingStage.primaryText
                  : OnboardingStage.line,
            ),
          ),
        ),
    ],
  );
}

class _Primary extends StatelessWidget {
  const _Primary({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        // **塗りの `primary` に白文字**（7.20:1）。地の上の文字ではないので
        // `primaryText` ではなく塗りのほう
        backgroundColor: OnboardingStage.primary,
        foregroundColor: OnboardingStage.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        // **書体はテーマから引き継ぐ**（日本語は Klee One）。素の `TextStyle` を
        // 渡すと、ボタンは既定の文字の形を**丸ごと差し替える**ので書体が落ち、
        // OS の書体で描かれる（gyumesy は素のまま。あちらは書体が Noto 一択で
        // 目立たなかった）
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        shape: const StadiumBorder(),
      ),
      child: Text(label),
    ),
  );
}
