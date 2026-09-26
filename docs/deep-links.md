# ユニバーサルリンク / App Links

web（`https://ton-soku.com`）のリンクを踏んだ時に、ブラウザではなくアプリを開く。
**アプリ側とweb側の 2 か所で対になって初めて成立する**（片側だけでは何も起きない）。

| | アプリ側（このリポジトリ） | web 側（tonsoku-frontend-web） |
|---|---|---|
| iOS | `ios/Runner/Runner.entitlements` の `applinks:ton-soku.com` | `/.well-known/apple-app-site-association` |
| Android | `android/app/src/main/AndroidManifest.xml` の `autoVerify` の intent-filter | `/.well-known/assetlinks.json` |

**受け口は通知のタップと同じ `deepLinkTarget` 1 本**（`lib/features/notifications/domain/deep_link.dart`。
リンクの受け取りは `lib/app.dart` の `_listenAppLinks`）。gyumesy-frontend-app が #90 で直した形を
写している（最後に踏まれた 1 本を `getLatestLink` で取り直す・Flutter 内蔵のディープリンクを切る）。

## 名乗る面

**`deepLinkTarget` がアプリ内で開ける面だけ。** 開けない面を名乗ると、Android では外部ブラウザへ
逃がした 1 本が自分へ戻って**際限なく往復する**（gyumesy の実測: 2000 回超の自己起動で ANR）。

| 面 | 名乗る | 理由 |
|---|---|---|
| `/`・`/articles`・`/articles/{slug}` | ✅ | ホーム・記事一覧・記事 |
| `/map` | ✅ | マップのタブ。**web の `/map/` はアプリへ誘導する LP**（Issue #30。絞り込みは下の「マップの絞り込み」） |
| `/coupon`・`/calendar`・`/ranking`・`/notifications` | ✅ | クーポンはタブ、残りはメニューから開く画面 |
| `/category/{slug}` | ❌ | **とん速のホームにはカテゴリのタブが無い**（gyumesy は名乗っている） |
| `/about`・`/legal/*` | ❌ | アプリは web で表示する方針（メニューから web を開く） |
| RSS・sitemap・`/api/*`・アセット | ❌ | HTML の面ではない |

ロケール（`/en`・`/zh`）も同じ規則。**末尾スラッシュの有無で 2 本ずつ**並べる
（web は常に末尾スラッシュ付きで出すが、スラッシュ無しで貼られた URL も拾う）。

**面を増やす時は 3 か所を一緒に直す**: `deepLinkTarget`・`AndroidManifest.xml`・下の AASA
（web に置くものの写し）。3 つのずれは `test/features/notifications/deep_link_test.dart` が
止める（名乗る面が全部開けること・マニフェストと下の AASA が同じ面を名乗っていること）。
**ただし web に実際に置かれた AASA はこのリポジトリのテストでは見られない**（下の JSON を
直したら web のセッションに同じ変更を頼む）。

## マップの絞り込み

**web の `/map/` はアプリへ誘導する LP で、そこのリンクがアプリのマップを開く**（Issue #30）。
絞り込みは**ハッシュ**で渡す（web のカレンダーの `/calendar/#category=…&month=…` と同じ形）:

```
https://ton-soku.com/map/#menu=177979,174161&brand=standalone,matsuya&include=1
```

| 鍵 | 値 | 意味 |
|---|---|---|
| `menu` | `campaign_id`（カンマ区切り） | 店舗限定の品で絞る |
| `brand` | `standalone`・`matsuya`・`mycurry`（カンマ区切り） | 松のや専門店・松屋併設・マイカリー食堂併設で絞る |
| `include` | `1` | 売り切れ・終売の店も含める |

- **知らない値は黙って捨てる**（配信から消えた品・知らないブランド）。読める値が 1 つも
  無ければ、絞り込みには触らずにマップを開く
- **マップが既に開いていても、今の絞り込みを丸ごと置き換える**
- **店舗限定の表示が閉じている時**（リワード動画を見ていない）は品の印は出ない。いつもの
  流れで開放すると、リンクの品で絞られた状態になる
- `brand` があれば、普段は畳んでいる併設の段を開いて見せる
- 読み書きは `lib/features/map/domain/map_link_filter.dart`（`MapLinkFilter`）1 か所。
  アプリの中の行き先は**クエリ**（`/map?menu=…`。`AppRoutes.calendar` と同じ理由）で、
  ハッシュからの読み替えは `deepLinkTarget` がする

## web に置くもの

**置くのは web のセッションの仕事**（このリポジトリからは web を触らない）。gyumesy-frontend-web は
AASA を `scripts/prepare-locale-assets.mts` で `ROUTES` とロケール表から生成している
（`APP_LINK_ROUTES` で面ごとに `exact` / `prefix` / `none` を決め、ページを足した人が必ず
決める形）。**とん速の web も同じ作りにするのがよい**（手書きだとロケールを増やした時に漏れる）。

### `/.well-known/apple-app-site-association`

- **拡張子なしのファイル名**で置き、**`Content-Type: application/json`** で返す。**リダイレクト不可**
  （Cloudflare Pages は拡張子から Content-Type を決めるので、`public/_headers` で明示する。
  gyumesy-frontend-web の `public/_headers` と同じ）
- `components` は**先に一致したものが勝つ**。ここは名乗るものだけを並べる allowlist なので、
  載せていない URL は一致せず名乗られない（exclude は要らない）
- `comment` は Apple が用意している説明用のキー。Apple の CDN を通るので ASCII で書く
- **`/articles/*` は深さを問わない**（`/articles/x/y/` も名乗る）。iOS では開けない面を名乗っても
  往復しない（アプリ内のブラウザで開くだけ）ので、gyumesy と同じ形でよい

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": [
          "29LP73942P.com.gyumesy.tonsoku"
        ],
        "components": [
          {
            "/": "/",
            "comment": "home (ja)"
          },
          {
            "/": "/calendar",
            "comment": "calendar (ja)"
          },
          {
            "/": "/calendar/",
            "comment": "calendar (ja)"
          },
          {
            "/": "/coupon",
            "comment": "coupon (ja)"
          },
          {
            "/": "/coupon/",
            "comment": "coupon (ja)"
          },
          {
            "/": "/ranking",
            "comment": "ranking (ja)"
          },
          {
            "/": "/ranking/",
            "comment": "ranking (ja)"
          },
          {
            "/": "/notifications",
            "comment": "notifications (ja)"
          },
          {
            "/": "/notifications/",
            "comment": "notifications (ja)"
          },
          {
            "/": "/map",
            "comment": "map (ja)"
          },
          {
            "/": "/map/",
            "comment": "map (ja)"
          },
          {
            "/": "/articles",
            "comment": "articleBase (ja)"
          },
          {
            "/": "/articles/*",
            "comment": "articleBase (ja)"
          },
          {
            "/": "/en",
            "comment": "home (en)"
          },
          {
            "/": "/en/",
            "comment": "home (en)"
          },
          {
            "/": "/en/calendar",
            "comment": "calendar (en)"
          },
          {
            "/": "/en/calendar/",
            "comment": "calendar (en)"
          },
          {
            "/": "/en/coupon",
            "comment": "coupon (en)"
          },
          {
            "/": "/en/coupon/",
            "comment": "coupon (en)"
          },
          {
            "/": "/en/ranking",
            "comment": "ranking (en)"
          },
          {
            "/": "/en/ranking/",
            "comment": "ranking (en)"
          },
          {
            "/": "/en/notifications",
            "comment": "notifications (en)"
          },
          {
            "/": "/en/notifications/",
            "comment": "notifications (en)"
          },
          {
            "/": "/en/map",
            "comment": "map (en)"
          },
          {
            "/": "/en/map/",
            "comment": "map (en)"
          },
          {
            "/": "/en/articles",
            "comment": "articleBase (en)"
          },
          {
            "/": "/en/articles/*",
            "comment": "articleBase (en)"
          },
          {
            "/": "/zh",
            "comment": "home (zh)"
          },
          {
            "/": "/zh/",
            "comment": "home (zh)"
          },
          {
            "/": "/zh/calendar",
            "comment": "calendar (zh)"
          },
          {
            "/": "/zh/calendar/",
            "comment": "calendar (zh)"
          },
          {
            "/": "/zh/coupon",
            "comment": "coupon (zh)"
          },
          {
            "/": "/zh/coupon/",
            "comment": "coupon (zh)"
          },
          {
            "/": "/zh/ranking",
            "comment": "ranking (zh)"
          },
          {
            "/": "/zh/ranking/",
            "comment": "ranking (zh)"
          },
          {
            "/": "/zh/notifications",
            "comment": "notifications (zh)"
          },
          {
            "/": "/zh/notifications/",
            "comment": "notifications (zh)"
          },
          {
            "/": "/zh/map",
            "comment": "map (zh)"
          },
          {
            "/": "/zh/map/",
            "comment": "map (zh)"
          },
          {
            "/": "/zh/articles",
            "comment": "articleBase (zh)"
          },
          {
            "/": "/zh/articles/*",
            "comment": "articleBase (zh)"
          }
        ]
      }
    ]
  }
}
```

### `/.well-known/assetlinks.json`

**指紋は 2 つ要る**（アップロード鍵の指紋は `docs/setup-app.md` の「済んだもの（とん速）」）:

- **アップロード鍵**（`keytool -list -v -keystore android/keystore/upload.jks -alias upload` の SHA256）
  —— 手元で入れた端末・クローズドテストの前に手で入れた端末
- **Play のアプリ署名鍵**（Play Console →「アプリの完全性」→「アプリの署名」の SHA-256）
  —— **ストアから入れた端末はこちらで署名されている。** これが無いと、ストア版だけ
  リンクがブラウザで開く

```json
[
  {
    "relation": [
      "delegate_permission/common.handle_all_urls"
    ],
    "target": {
      "namespace": "android_app",
      "package_name": "com.gyumesy.tonsoku",
      "sha256_cert_fingerprints": [
        "<Play のアプリ署名鍵の SHA-256>",
        "<アップロード鍵の SHA-256>"
      ]
    }
  }
]
```

**片方の指紋でも先に置く**（web #162 でアップロード鍵の指紋 1 つで置いた）。**Play のアプリ署名鍵の
指紋は、最初の AAB を上げた後に出る**ので、出たら web のセッションに送って配列に足してもらう
（`docs/release-state.md` の 16b）。それまでは、ストアから入れた端末ではリンクがブラウザで開く。
AASA は置いてある（web #144・#148）。

## 確かめ方

**この形の誤りはビルドも analyze もテストも通る。** 実機（またはエミュレータ /
シミュレータ）で踏んで確かめる。

```bash
# Android: App Links の検証状態
adb shell pm get-app-links com.gyumesy.tonsoku
# Android: リンクを踏んだのと同じ intent を投げる
adb shell am start -a android.intent.action.VIEW -d "https://ton-soku.com/articles/<slug>/"
# iOS シミュレータ: リンクを開く
xcrun simctl openurl booted "https://ton-soku.com/articles/<slug>/"
```

- **iOS は AASA を Apple の CDN 越しに取る**（`https://app-site-association.cdn-apple.com/a/v1/ton-soku.com`）。
  web に置いてから反映まで時間がかかる
- 確かめる面: 記事・`/en/` 付きの記事・カレンダー（`#category=campaign` 付き）・通知設定・
  マップ（`#menu=<campaign_id>&brand=standalone` 付き。**マップを開いたまま別の絞り込みの
  リンクを踏み、置き換わること**も）・
  **名乗っていない面（`/about/`・`/category/<slug>/`）がブラウザで開くこと**
- **背面から踏む**: 記事 A を開いて背面へ → 記事 B のリンクを踏む → **B が開くこと**
  （gyumesy で A が開いていた不具合。`_syncLatestLink` が直している）
