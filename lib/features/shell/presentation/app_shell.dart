import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/menu/presentation/menu_sheet.dart';
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

  void _toggleSheet() {
    // 開いている時にもう一度押したら閉じる（web と同じ）
    if (_sheetOpen) {
      _sheetKey.currentState?.close();
      return;
    }
    setState(() => _sheetOpen = true);
  }

  void _goBranch(int index) {
    // タブへ移る時はシートを畳む。web はページ遷移なので必ず閉じる
    if (_sheetOpen) _sheetKey.currentState?.close();
    navigationShell.goBranch(
      index,
      // 同じタブをもう一度押した時は、そのタブのルートまで戻す
      initialLocation: index == navigationShell.currentIndex,
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
            ),
        ],
      ),
      // **`NavigationBar` を使わない。** 既定の高さ（80px）と余白が web
      // （56px・アイコン 22px・ラベル 10px・間隔 4px）と合わず、画面下が
      // そのぶん狭くなる（gyumesy-frontend-app と同じ判断）
      bottomNavigationBar: Semantics(
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
    );

    // シートが開いている間は、**戻る操作を横取りする**（言語・その他を開いて
    // いればメニューへ、メニューなら閉じる。web が履歴を 2 段積んでいるのと同じ）。
    //
    // **`PopScope` では止まらない。** go_router は戻る操作を深い側のナビゲータ
    // （タブの中）から処理するので、タブに記事を積んでいるとそこで消費され、
    // シェルの `PopScope` まで届かない ―― **シートは開いたまま、見えないところで
    // 記事が閉じた**（PR #17 のレビューで再現。gyumesy も同じ作りで同じ挙動）。
    // `BackButtonListener` は Router の戻るボタンの受け口に、**置いた時点で
    // 優先権を取って**加わるので、タブのナビゲータより先に受け取れる
    if (!_sheetOpen) return scaffold;
    return BackButtonListener(
      onBackButtonPressed: () async {
        _sheetKey.currentState?.handleBack();
        return true;
      },
      child: scaffold,
    );
  }
}
