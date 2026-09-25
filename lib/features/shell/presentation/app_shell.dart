import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/ads/ad_banner.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/router/app_router.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/menu/presentation/menu_sheet.dart';
import 'package:tonsoku/features/notifications/domain/deep_link.dart';
import 'package:tonsoku/features/notifications/presentation/notification_settings_controller.dart';
import 'package:tonsoku/features/shell/presentation/menu_screen_request.dart';
import 'package:tonsoku/features/shell/presentation/widgets/nav_item.dart';

/// 画面下に固定するグローバルナビ。
///
/// 並びは **ホーム / マップ / クーポン / メニュー**（ユーザーの指定）。web の下タブ
/// （ホーム / カレンダー / クーポン / ランキング / メニュー）とは違う ——
/// **アプリにはマップがあり、あぶれたカレンダー・ランキングはメニューに入る。**
///
/// **スクロールで隠さない。** 隠すと移動のたびに一度上へ払う操作が要る
/// （web・gyumesy と同じ）。
///
/// **「メニュー」だけはタブへ移らずシートを開く**（web と同じ）。シートは本文の
/// 上・ナビの下に重ねるので、開いている間もナビは暗くならず押せる
/// （[MenuSheet]。gyumesy-frontend-app の `AppShell` と同じ組み方）。
class AppShell extends ConsumerStatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// web の `--spacing-bottom-nav-inner`（3.5rem）。
  static const _height = 56.0;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _sheetKey = GlobalKey<MenuSheetState>();
  bool _sheetOpen = false;

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    // **設定アプリから戻ってきたら通知設定へ戻す**（gyumesy と同じ）。
    //
    // Android は**実行時権限を取り消されるとアプリのプロセスを殺す**ので、
    // 通知を切って戻るとコールドスタートになり、初期ルート（ホーム）から
    // 始まってしまう。送り出す時に付けた印をここで見る
    // （`NotificationStore.readReturning` に経緯を書いてある）。
    //
    // **最初のフレームより後に積む。** ブランチのナビゲータはまだ組み上がって
    // いない
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _restoreNotifications(),
    );
    // **外から来た URL（通知のタップ）からもメニューの画面を積む。** 逆に、
    // 別の面へ移った時は畳む。行き先ではなく要求で受けている理由は
    // [menuScreenRequest]
    menuScreenRequest.addListener(_consumeScreenRequest);
    // **購読より前に積まれた要求も拾う。** 終了状態から通知で起動すると、
    // 画面が組み上がるより先に要求だけが置かれていることがある
    // （`pushedLink` を `TonsokuApp` が同じ形で拾っているのと同じ理由）
    _consumeScreenRequest();
  }

  @override
  void dispose() {
    menuScreenRequest.removeListener(_consumeScreenRequest);
    super.dispose();
  }

  /// 見ていない要求。**回数で見る**（同じ通知を続けて開いた時も積み直せるように、
  /// 要求側は値を増やすだけ。[menuScreenRequest]）。
  int _seenScreenRequests = 0;

  /// 見ていない要求があれば実行する。
  ///
  /// **次のフレームで動かす。** 終了状態からの起動では、ブランチのナビゲータが
  /// まだ組み上がっていない。畳む側は、`go` による行き先の組み替えより後に
  /// 動かす必要がある（いま居るタブを `go` の後の値で見るため）。
  void _consumeScreenRequest() {
    final request = menuScreenRequest.value;
    if (request == null || request.seq == _seenScreenRequests) return;
    _seenScreenRequests = request.seq;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = request.target;
      if (target == null) {
        _foldMenuScreens();
      } else {
        _openFromMenu(target.location);
      }
    });
    // **フレームを起こす。** 要求は画面の外（通知のタップ）から来るので、
    // 何も描き直す予定が無いと、上のコールバックが次に何かが動くまで走らない
    // （テストで踏んだ: 要求を置いても通知設定が積まれなかった）
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// メニューから開いた画面を、**いま居るタブ以外**は次に戻った時に畳む。
  ///
  /// いま居るタブは `go` で積み直されているので、印を消すだけでよい（残すと、
  /// 通知から開いた記事までタブを移った時に畳まれる）。
  void _foldMenuScreens() {
    final current = navigationShell.currentIndex;
    for (final branch in _menuScreenBranches.toList()) {
      _menuScreenBranches.remove(branch);
      if (branch != current) _foldOnReturn.add(branch);
    }
  }

  void _restoreNotifications() {
    if (!mounted) return;
    final store = ref.read(notificationStoreProvider);
    if (!store.readReturning()) return;
    // **見たら消す。** 残すと次に普通に起動した時にも開く
    store.writeReturning(value: false);
    _openFromMenu(const MenuScreenTarget(MenuScreen.notifications).location);
  }

  void _toggleSheet() {
    // 開いている時にもう一度押したら閉じる（web と同じ）
    if (_sheetOpen) {
      _sheetKey.currentState?.close();
      return;
    }
    setState(() => _sheetOpen = true);
  }

  /// メニューから開いた画面を積んでいるタブ。
  final _menuScreenBranches = <int>{};

  /// 戻ってきた時に最初の画面から開くタブ（[_goBranch]）。**タブごとに持つ**
  /// ―― 1 つだけだと、ホームでランキング → クーポンでもランキング → ホーム、
  /// の順で移った時に印が上書きされ、ホームにランキングが残った（PR #20 の
  /// レビューで再現）。
  final _foldOnReturn = <int>{};

  /// メニューから開く画面を**いま居るタブの中に積む**（下タブを隠さず、戻ると
  /// そのタブへ帰る）。**シートを閉じてから積む** ―― 残したまま積むと、戻って
  /// きた時にシートが開いたままになり、下の画面が見えない（gyumesy の注記）。
  ///
  /// **タブを移ったら畳む**（[_goBranch]）。メニューから開く画面はどのタブにも
  /// 属さないので、積んだタブに残すと、別のタブへ移って戻った時に出てくる
  /// （ユーザーの指摘: ホーム → ランキング → クーポン → ホームでランキングが
  /// 出た。gyumesy が通知設定を畳むのと同じ理由）。
  ///
  /// **いま一番上に同じ画面が出ていたら積まない**（gyumesy の通知設定と同じ）。
  /// 通知のタップやメニューから同じ画面を開き直すたびに積むと 2 枚重なり、
  /// 戻るを押しても見た目が変わらないので「戻るが効かない」に見える。
  Future<void> _openFromMenu(String Function(String prefix) location) async {
    _sheetKey.currentState?.close();
    final branch = navigationShell.currentIndex;
    final router = GoRouter.of(context);
    final next = location(AppRoutes.branchPrefixes[branch]);
    if (router.state.uri.toString() == next) {
      return;
    }
    _menuScreenBranches.add(branch);
    await router.push<void>(next);
    // 戻るで閉じた。**畳む印を消す**（残すと、そのあと同じタブに積んだ記事まで
    // タブを移った時に畳まれる）
    _menuScreenBranches.remove(branch);
  }

  void _goBranch(int index) {
    // タブへ移る時はシートを畳む。web はページ遷移なので必ず閉じる
    if (_sheetOpen) _sheetKey.currentState?.close();
    // **メニューから開いた画面を積んだタブを離れたら、そのタブへ戻る時に
    // 最初の画面から開く**（[_openFromMenu]）。その画面から開いた記事も一緒に
    // 畳む。**離れる瞬間に畳まない** ―― 同じフレームで `goBranch` を 2 回呼ぶと
    // 後のほうだけが効き、畳む側が捨てられる（テストで確かめた）
    for (final folded
        in _menuScreenBranches.where((b) => b != index).toList()) {
      _menuScreenBranches.remove(folded);
      _foldOnReturn.add(folded);
    }
    final fold = _foldOnReturn.remove(index);
    navigationShell.goBranch(
      index,
      // 同じタブをもう一度押した時は、そのタブのルートまで戻す
      initialLocation: index == navigationShell.currentIndex || fold,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(messagesProvider);
    final colors = context.colors;

    // **アイコンは Material の outlined**（web は Material Symbols Outlined の
    // `home` / `local_activity` / `menu` を使っている）。**マップは web に無いので
    // 位置のピン（`location_on`）**。折りたたんだ地図の絵（`map`）は小さいと
    // 何の絵か読めなかった（ユーザーの指摘）
    final items = <({IconData icon, String label, int? branch})>[
      (icon: Icons.home_outlined, label: t.navHome, branch: 0),
      (icon: Icons.location_on_outlined, label: t.navMap, branch: 1),
      (icon: Icons.local_activity_outlined, label: t.navCoupon, branch: 2),
      // メニューはブランチを持たない（シートを開くだけ）
      (icon: Icons.menu, label: t.navMenu, branch: null),
    ];

    final scaffold = Scaffold(
      body: Stack(
        children: [
          // **暗幕の下は読み上げからも外す。** 暗くしてタップを止めるだけだと、
          // スクリーンリーダーの activate は `SemanticsAction.tap` を直に送るので
          // **ヒットテストを迂回して発火し**、シートが開いたまま記事へ飛べる
          // （gyumesy の注記。web も暗幕の下を `inert` にしている）
          ExcludeSemantics(excluding: _sheetOpen, child: navigationShell),
          if (_sheetOpen)
            MenuSheet(
              key: _sheetKey,
              onClose: () => setState(() => _sheetOpen = false),
              onOpenCalendar: () => _openFromMenu(AppRoutes.calendar),
              onOpenRanking: () => _openFromMenu(AppRoutes.ranking),
              onOpenNotifications: () => _openFromMenu(AppRoutes.notifications),
            ),
        ],
      ),
      // **`NavigationBar` を使わない。** 既定の高さ（80px）と余白が web
      // （56px・アイコン 22px・ラベル 10px・間隔 4px）と合わず、画面下が
      // そのぶん狭くなる（gyumesy-frontend-app と同じ判断）
      //
      // **下タブの上にアンカーの広告を積む**（全タブ。[WithAnchoredAd]）。
      // `bottomNavigationBar` の中に入れるので、本文は広告の上で終わり、
      // 覆われない
      bottomNavigationBar: WithAnchoredAd(
        nav: Semantics(
          container: true,
          label: t.navLabel,
          child: Container(
            // **地は生成り（`bg`）。** web の `CoBottomNav` はヘッダーと同じ地色で、
            // 上罫を残している（本文の面と色が違っても、線が無いと境目が弱い）
            decoration: BoxDecoration(
              color: colors.bg,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            // ホームバーのぶんは器が持つ（中身の高さは web と同じに保つ）
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: AppShell._height,
                child: Row(
                  children: [
                    for (final item in items)
                      Expanded(
                        child: NavItem(
                          icon: item.icon,
                          label: item.label,
                          // **シートを開いても現在地は消さない。** どのタブに
                          // いたかは変わっていないので、消すと戻り先を見失う
                          isActive: item.branch == null
                              ? _sheetOpen
                              : navigationShell.currentIndex == item.branch,
                          onTap: item.branch == null
                              ? _toggleSheet
                              : () => _goBranch(item.branch!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // シートが開いている間は、**戻る操作を横取りする**（言語・その他を開いて
    // いればメニューへ、メニューなら閉じる。web が履歴を 2 段積んでいるのと同じ）。
    //
    // **受け口は 2 つ要る。どちらも外さないこと。**
    //
    // - **`BackButtonListener`** … go_router は戻る操作を深い側のナビゲータ
    //   （タブの中）から処理するので、タブに記事を積んでいるとそこで消費され、
    //   シェルの `PopScope` まで届かない ―― **シートは開いたまま、見えない
    //   ところで記事が閉じた**（PR #17 のレビューで再現。gyumesy も同じ作り）。
    //   これは Router の戻るボタンの受け口に**置いた時点で優先権を取って**加わる
    //   ので、タブのナビゲータより先に受け取れる
    // - **`PopScope(canPop: false)`** … **OS に「戻るはアプリが扱う」と伝える役**
    //   （`SystemNavigator.setFrameworkHandlesBack(true)`）。何も積んでいない
    //   タブでは他にこれを送るものが無く、Android 16（予測型「戻る」が既定）
    //   では**戻る操作がアプリに届かず、シートを閉じないままホーム画面へ抜ける**
    //   （PR #17 の 2 回目のレビュー。一度 `PopScope` を外してこれを起こした）
    return PopScope(
      canPop: !_sheetOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _sheetKey.currentState?.handleBack();
      },
      child: _sheetOpen
          ? BackButtonListener(
              onBackButtonPressed: () async {
                _sheetKey.currentState?.handleBack();
                return true;
              },
              child: scaffold,
            )
          : scaffold,
    );
  }
}
