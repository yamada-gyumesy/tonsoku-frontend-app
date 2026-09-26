import 'package:flutter/foundation.dart';

import 'package:tonsoku/features/notifications/domain/deep_link.dart';

/// メニューから開く画面（カレンダー・ランキング・通知設定）を積む / 畳む要求。
/// **値は連番**で、中身に意味は無い（増えたことと、積むのか畳むのかだけを見る）。
///
/// gyumesy-frontend-app の `open_notifications_request.dart` を写し、通知設定だけ
/// だったものをメニューの画面全部に広げた（とん速ではカレンダー・ランキングも
/// メニューから開く画面なので）。
///
/// **行き先ではなく要求を置く。** メニューの画面はどのタブにも属さず、タブを
/// 移ったら畳む画面なので（`AppShell` の `_openFromMenu`）、**どのタブの中に
/// 積むか・畳む印をどこに付けるか**を知っているのは `AppShell` だけ。
/// 通知のタップは `runApp` より前にも届く（[deepLinkTarget] を引くのは
/// `TonsokuApp`）ので、シェルが組み上がるまで要求だけを置いておける形にする。
///
/// **畳む側も要求で渡す。** 通知のタップで `go` すると、移った先のタブは
/// 積み直されるが、**他のタブに積んだメニューの画面は残る**（`go` は他の
/// ブランチに触らない）。残したままだと、下タブでそのタブへ戻った時に出てくる。
@immutable
class MenuScreenRequest {
  const MenuScreenRequest({required this.seq, this.target});

  final int seq;

  /// 積む画面。**null なら畳む。**
  final MenuScreenTarget? target;
}

/// 最後に届いた要求。受けるのは `AppShell`。
final menuScreenRequest = ValueNotifier<MenuScreenRequest?>(null);

/// メニューの画面を今のタブに積んでもらう。
void requestOpenMenuScreen(MenuScreenTarget target) => _request(target);

/// メニューから開いた画面を畳んでもらう。
///
/// **外から来た URL で別の面へ移る時に呼ぶ**（上の doc）。
void requestFoldMenuScreens() => _request(null);

void _request(MenuScreenTarget? target) =>
    menuScreenRequest.value = MenuScreenRequest(
      seq: (menuScreenRequest.value?.seq ?? 0) + 1,
      target: target,
    );

/// メニューのシートを「広告を外す課金」の画面で開いてもらう（Issue #42）。
///
/// **マップの動画の案内の「広告を非表示」から呼ぶ**（ユーザーの指定。案内の中では
/// 買わせず、説明のある購入の画面へ連れてくる）。受けるのは `AppShell`（シートの
/// 開閉を持っているのはあちら）。**回数で見る**（[menuScreenRequest] と同じ理由）。
final removeAdsSheetRequest = ValueNotifier<int>(0);

void requestOpenRemoveAds() => removeAdsSheetRequest.value++;
