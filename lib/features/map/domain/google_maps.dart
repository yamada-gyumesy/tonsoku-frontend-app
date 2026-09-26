import 'package:tonsoku/shared/models/shop.dart';

/// 店を Google マップで開く URL。
///
/// **店名で検索させる**（`api=1` の検索。Google が公開している形
/// https://developers.google.com/maps/documentation/urls/get-started ）。
///
/// **座標（`query=35.69,139.69`）にしない。** 座標で開くと、その地点に
/// 名前の無いピンが立つだけで、**店の情報（営業時間・口コミ・経路の行き先名）が
/// 出ない**。しかも配信の座標は Navitime のもので、Google の店の位置と数十 m
/// ずれることがあり、ビルの反対側にピンが立つ。
///
/// **店名だけで店が 1 つに決まる**: 配信の店名は「松のや 西新宿店」のように
/// 支店名まで入った正式名で、本番の 681 軒に重複が無い（2026-09-25 実測。
/// `test/features/map/google_maps_test.dart` が同じことを見ている）。
/// 住所を足すと住所の検索として扱われ、店ではなく番地にピンが立つことがあるので
/// 足さない。
///
/// **英語・中国語では訳した店名で引く**（`Matsunoya Nishi-Shinjuku`。Google は
/// 英語・中国語の名前でも店に当たる）。**訳が無い店**（`name` が null）は
/// `Matsunoya` とローマ字名で引く（日本語の店名は英語・中国語の面に無い。
/// 英語の屋号は web の CLAUDE.md「松のやと松屋を混ぜない」の `Matsunoya`）。
/// ローマ字名も無い店だけ座標で開く（上の理由で最後の手段）。
///
/// Google マップのアプリが入っていれば、この URL はアプリで開く（iOS の
/// ユニバーサルリンク・Android のアプリリンク）。
Uri googleMapsUri(Shop shop) => Uri.https('www.google.com', '/maps/search/', {
  'api': '1',
  'query':
      shop.name ??
      switch (shop.nameRoman) {
        final roman? => 'Matsunoya $roman',
        null => '${shop.lat},${shop.lon}',
      },
});
