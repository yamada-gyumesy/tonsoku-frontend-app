# Tonsoku Frontend App

とん速（松のや専門メディア）のネイティブアプリ（iOS / Android）。Flutter で構築する。

| | |
|---|---|
| Web 版 | [tonsoku-frontend-web](https://github.com/yamada-gyumesy/tonsoku-frontend-web)（https://ton-soku.com） |
| 配信 CDN | https://cdn.ton-soku.com （R2 バケット `tonsoku-cdn`） |
| 配信の作り手 | [tonsoku-backend-batch](https://github.com/yamada-gyumesy/tonsoku-backend-batch) |
| 下敷き | [gyumesy-frontend-app](https://github.com/yamada-gyumesy/gyumesy-frontend-app)（先にアプリ化してストア公開済み） |
| Bundle ID / package name | `com.gyumesy.tonsoku` |

**作りは gyumesy-frontend-app、見た目は tonsoku-frontend-web。** UI コードは web と共有せず、
**配信データ（R2 / cdn.ton-soku.com）だけを共有する**。判断の拠りどころは [CLAUDE.md](CLAUDE.md)。

## Web との違い

- Web は全ページを Astro でビルドしきって Cloudflare Pages に置いているが、アプリは **R2 から JSON を取得する**
- **下タブはホーム / マップ / クーポン / メニュー**。web の下タブにあるカレンダー・ランキングはメニューに入る
- **マップはアプリにしか無い**（店舗限定メニューの取扱店を地図で見せる）
- **X の返信（`x.json`）は持たない**（gyumesy と同じく UGC 判定を避けるため）

## 技術スタック

| 項目 | バージョン |
|------|-----------|
| Flutter | 3.44.0 |
| Dart | 3.12.0 |

- **hooks_riverpod** - 状態管理
- **go_router** - ルーティング
- **dio** - 配信データの取得
- **freezed / json_serializable** - モデル
- **shared_preferences / path_provider** - 設定値とキャッシュ
- **flutter_map / vector_map_tiles** - マップ（同梱の背景地図をベクターのまま描く）
- **geolocator** - マップの現在地
- **firebase_messaging / flutter_local_notifications** - プッシュ通知（下の「プッシュ通知」）
- **google_mobile_ads / app_tracking_transparency** - 広告（AdMob）と iOS の ATT
- **in_app_purchase** - 広告を外すアプリ内課金（買い切り。下の「広告を外す課金」）
- **app_links** - ユニバーサルリンク / App Links（[docs/deep-links.md](docs/deep-links.md)）
- **firebase_analytics** - GA4 の画面計測（下の「計測（GA4）」）

依存は**実際に使う時に足す**（gyumesy と同じ方針）。

## セットアップ

Flutter の版は `.tool-versions` が持つ（[mise](https://mise.jdx.dev/)）。**gyumesy-frontend-app と同じ版**で、版を増やさない。

```bash
mise install
flutter pub get
dart run build_runner build
```

## 開発

```bash
flutter run
```

ローカルの mock CDN（`tonsoku-frontend-web` の `mock-cdn/`）を見たい場合:

```bash
flutter run --dart-define=CDN_BASE_URL=http://localhost:4000
```

表示言語だけを切り替えて見たい場合（メニューの言語切替が入るまでの確認用）:

```bash
flutter run --dart-define=LOCALE=en
```

## コマンド

| コマンド | 説明 |
|---|---|
| `flutter analyze` | 静的解析 |
| `flutter test` | テスト |
| `dart run build_runner build` | freezed / json_serializable の生成物を更新 |
| `python3 tool/build_fonts.py` | 同梱書体を web の配布物から作り直す |
| `tool/build_map.sh` | マップの背景地図と駅（`assets/map/`）を作り直す（下の「マップの背景地図」） |
| `python3 tool/build_notification_icon.py` | Android の通知の小アイコン（`ic_stat_notification`）を web の `badge.png` から作り直す（下の「プッシュ通知」） |
| `dart run flutter_native_splash:create` | 起動画面を作り直す（下の「起動画面」） |
| `python3 tool/build_licenses.py` | ライセンス表記から外すパッケージ（配布物に入らないもの）の一覧を作り直す。依存を変えたら回す（CI が差分を見る） |

**生成物（`*.freezed.dart` / `*.g.dart`）はリポジトリにコミットする。** CI が生成し直して差分が出ないことを確認する。

CI は `.tool-versions` から Flutter の版を読んで固定し、`flutter pub get --enforce-lockfile` で `pubspec.lock` のとおりに解決する。

## ディレクトリ構成

```
lib/
  core/
    ads/        # 広告（AdMob）
    analytics/  # GA4 の画面計測（web と同じパス・題で送る）
    cdn/        # 配信データのパス解決と取得（stale-while-revalidate）
    config/     # 環境設定
    i18n/       # ロケール定義・UI固定文言
    network/    # CDN クライアント
    purchase/   # 広告を外すアプリ内課金（ストアとの境目・購入の状態）
    router/     # ルート定義
    storage/    # キャッシュ
    theme/      # 配色トークン・ThemeData
  features/     # 機能ごとに data / domain / presentation
  shared/       # 機能をまたぐモデル・部品
```

## 配信データ

CDN（`cdn.ton-soku.com`）から取得する。**日本語はルート、追加ロケールは `i18n/{locale}/` 配下**という名前空間の差は `core/cdn/cdn_paths.dart` に閉じている。

| ファイル | 用途 |
|---|---|
| `articles/feed.json` | 記事一覧（最新 200 件・配列） |
| `articles/{slug}.json` | 記事 1 本（`content` に Markdown） |
| `categories.json` / `tags.json` | カテゴリ・タグの表示ラベル（**ラベルの正**） |
| `calendar.json` | カレンダー |
| `coupon.json` | クーポン（404 を正常系として扱う） |
| `ranking.json` | ランキング |
| `recommended-menu.json` | おすすめメニュー |
| `limited/weeks.json` | 店舗限定の週ごとの状態 |
| `app/shop.json` / `app/limited.json` / `app/version.json` | マップ向け（店舗と店舗限定の取扱店）。**英語・中国語も `i18n/{locale}/app/` に出る**（面が無い間の扱いは `MapRepository`） |

**形は gyumesy とほぼ同じ**だが、記事本体の置き場（gyumesy は `articles/{slug}/index.md`）と、`null` を出す鍵がある点が違う（`lib/shared/models/article_meta.dart`）。

**英語・中国語の面は、訳が無い値を日本語に落とさず `null` で出す**（店名・住所・営業時間・品名。tonsoku-backend-batch#286）。英語・中国語の画面に日本語を出さないのはユーザーの決定で、アプリも日本語に落とさない（描き方は各モデルの doc）。

**配信データの形は CDN の実物を見る**（`curl -s https://cdn.ton-soku.com/articles/feed.json | head`）。`tonsoku-backend-batch/output/` は R2 配信が始まる前の古い形なので見ないこと（web の CLAUDE.md と同じ注意）。

## プッシュ通知

作りは gyumesy-frontend-app のまま（FCM のトピック購読・通知設定の画面・タップで記事を開く）。

- **トピックは `tonsoku.category.<slug>`**（`<slug>` は `categories.json` と同じ。ロケールは入れない）。**送る側（tonsoku-backend-batch の `app/notify/push.py`）と web の購読口（tonsoku-frontend-web の `functions/api/fcm/topics.ts`）と同じ名前でないと、購読できるのに届かない。** アプリは web の購読口を通さず、SDK の `subscribeToTopic` で直接購読する（`lib/features/notifications/data/messaging_service.dart`）
- **Firebase の設定ファイル**（`android/app/google-services.json` / `ios/Runner/GoogleService-Info.plist`）は公開値なのでコミットする（gyumesy と同じ）。作り手は tonsoku-infra-terraform（Firebase プロジェクト `tonsoku`）。APNs の鍵は Firebase に登録済み
- **Android の通知の小アイコンは白＋透明の専用の絵**（`ic_stat_notification`）。ランチャーアイコンを指すと白い四角になる。web の `public/badge.png` を `assets/icon/notification_icon.png` に写して `python3 tool/build_notification_icon.py` で作る
- **通知のタップの行き先は `deepLinkTarget` の 1 本で決める**（`lib/features/notifications/domain/deep_link.dart`）。アプリに無い面は外部ブラウザで開く。ユニバーサルリンク / App Links も同じ入口に合流させている（[docs/deep-links.md](docs/deep-links.md)）
- iOS の最低対応は **15.0**（firebase-core / firebase-messaging が要求する。gyumesy と同じ）

## 計測（GA4）

**web と同じ GA4 プロパティ（`552748808`「とん速 | 松のや速報」）に入る**（Firebase プロジェクト `tonsoku` のアプリのストリーム。作り手は tonsoku-infra-terraform）。作りは gyumesy-frontend-app のまま。

- **画面ごとに `screen_view` を 1 回送る**（`lib/core/analytics/`）。**スクリーン名は web の `<title>`、スクリーン クラスは web のパス**にしてあり、GA4 の統合ディメンション（「ページタイトルとスクリーン名」「ページパスとスクリーン クラス」）で**同じ画面の app と web が 1 行に並ぶ**。理由と `page_view` を送らない経緯は `analytics.dart` の doc
- **自動の `screen_view` は切ってある**（iOS の `Info.plist` の `FirebaseAutomaticScreenReportingEnabled`、Android の `google_analytics_automatic_screen_reporting_enabled`）。Flutter は画面が 1 枚なので、自動では全画面が 1 行に潰れる
- **画面を足したら `ScreenPath` に足し、`TrackScreen` で包む。** 対応は `test/core/analytics/screen_path_test.dart` が全画面・全ロケールで持っている

| 画面 | スクリーン クラス（= web のパス） | スクリーン名（= web の `<title>`、日本語） |
|---|---|---|
| ホーム | `/` | `とん速 \| 松のや速報` |
| 記事一覧 | `/articles/` | `記事一覧 \| とん速` |
| 記事 | `/articles/{slug}/` | `{記事の題} \| とん速` |
| カレンダー | `/calendar/` | `松のやカレンダー \| とん速` |
| クーポン | `/coupon/` | `松のやのクーポン \| とん速` |
| ランキング | `/ranking/` | `ランキング \| とん速` |
| 通知設定 | `/notifications/` | `通知設定 \| とん速` |
| マップ（web は誘導の LP） | `/map/` | `マップ \| とん速` |
| ライセンス（web に無い） | `licenses` | `licenses` |
| オンボーディング（web に無い） | `onboarding/intro` / `onboarding/notifications` | 同左 |

英語・中国語は web と同じく `/en/` `/zh/` が付き、題の接尾辞は `Tonsoku` / `豚速`。**web に無い画面はスラッシュの無い名前で送る**（web のパスと見分けが付き、web に同名のページができても混ざらない）。

## オンボーディング

**初回起動だけ 2 枚を本体の上に重ねる**（サービス紹介 → 通知の許可。`lib/features/onboarding/`。作りは gyumesy-frontend-app のまま）。一度閉じたら二度と出さない（版では出し直さない）。

- **通知の許可はいきなり求めない**（2 枚目で何が届くかを見せてから）。許可すると全カテゴリを購読する。**カテゴリが届くまで最大 5 秒待つ**（届く前に進むと購読 0 件になる。gyumesy の 79d2ce4）
- **広告の同意（UMP）と ATT はオンボーディングを閉じてから出す**（下の「広告」）
- 絵（`assets/onboarding/`）は web の OGP 画像を縮めたもの。**アプリのスクリーンショットが撮れたら差し替える**（手順は `OnboardingPage` の doc）

## 広告

AdMob。置き場と方針は [CLAUDE.md](CLAUDE.md) の「広告」。

| 何を | どこに | いまの値 |
|---|---|---|
| 広告ユニット ID（枠ごと・OS ごと。アンカー / 記事 / マップのリワード） | `lib/core/config/ad_config.dart` の `productionIos` / `productionAndroid` | 本番（発行者 `pub-7838125849960397`） |
| AdMob のアプリ ID（iOS） | `ios/Runner/Info.plist` の `GADApplicationIdentifier` | 本番 |
| AdMob のアプリ ID（Android） | `android/app/src/main/AndroidManifest.xml` の `com.google.android.gms.ads.APPLICATION_ID` | 本番 |

- **release 以外（`flutter run`）は枠の ID に関係なく Google のテスト用 ID で出る**（テスト用の広告は数えられない）
- **アプリ ID とユニット ID は同じ AdMob のアプリのものをそろえる。** 片方だけ差し替えると広告が配信されない
- **同意（UMP）のメッセージは AdMob の「プライバシーとメッセージ」で公開しておく**（公開していないと同意の画面が出ない）
- 起動の順は **同意（UMP）→ ATT → SDK の初期化**（`lib/core/ads/ads_controller.dart`。呼ぶのは `main.dart` の 1 か所）。**初回起動はオンボーディングを閉じてから始める**（ATT を通知の許可やオンボーディングに重ねない。`lib/features/onboarding/data/ads_after_onboarding.dart`）

## 広告を外す課金

**買い切り（非消耗型）で、買った端末では広告を一切出さない**（Issue #42。判断の拠りどころは
[CLAUDE.md](CLAUDE.md) の「広告」）。サーバーは持たず、端末の保存とストアの購入記録だけで判定する。

### ストアに登録する商品

**定義の出どころは [`iap_products.yaml`](iap_products.yaml) の 1 か所だけ**（ストアへの登録は
そこを読む `register_iap` の lane。手順は [docs/setup-app.md](docs/setup-app.md) の「アプリ内課金の商品」）。

| 商品 ID（iOS / Android 共通） | 種類 | 価格 | 表示名（ja / en / zh） |
|---|---|---|---|
| `tonsoku.non_consumable.remove_ads` | 非消耗型（iOS: Non-Consumable / Play: アプリ内アイテム（管理対象）） | 550 円（税込） | 広告を非表示にする / Remove ads / 移除广告 |

- **商品 ID は登録した後に変えられない・使い回せない。** アプリが読む写し（`lib/core/purchase/purchase_gateway.dart` の `removeAdsProductId`）と yaml が食い違うと誰も買えないので、`test/core/purchase/iap_products_test.dart` が突き合わせている
- **価格はアプリに持たない**（画面に出すのはストアが返した表示価格）

### 動き

- **導線はメニュー（「広告を非表示にする」「購入を復元」）とマップの動画の案内の 2 か所だけ**。下の広告バナーの近くには置かない
- **買ったことは端末に残す**（`ads_removed`）。起動した瞬間から広告の SDK・同意（UMP）・ATT に触れない（`adConfigProvider`）
- **起動のたびにストアの購入記録と突き合わせる**（`RemoveAdsController.start`。呼ぶのは `main.dart` の 1 か所）。ストアが「持っていない」とはっきり答えた時（返金・取り消し）だけ広告を戻し、聞けない時（圏外など）は端末の記録のまま
- **ストアに触るのは `lib/core/purchase/purchase_gateway.dart` だけ**。テストは偽物に差し替える（`purchaseGatewayProvider`。広告の `adGatewayProvider` と同じ）
- **商品が取れるのは、ストアで商品が使える状態になってから**（iOS は価格まで付いた後・Android は有効化の後。試し方は docs/setup-app.md の「試し方」）。取れない間、画面は価格を出さず、押すと「ストアに接続できませんでした」と出る

## 書体

**日本語は Klee One、英語・中国語は Noto Sans JP**（web と同じ使い分け）。実体は web が npm で持っている配布物から `tool/build_fonts.py` が作る（web 側で `yarn install` 済みであること）。

## マップの背景地図

**背景地図はアプリに同梱する**（`assets/map/`。ユーザーの判断）。配信（R2）から取らないので、圏外でも地図が出て、通信量もかからない。ほぼ更新しない前提。

| ファイル | 中身 |
|---|---|
| `assets/map/japan.pmtiles`（約 30MB） | [Protomaps](https://protomaps.com/) の basemap（OpenStreetMap 由来）から日本の範囲（経度 122〜154・緯度 20〜46）を切り出したベクタータイル。**z0〜11 だけ**で、層は陸（`earth`）・湖と川（`water`。海は陸の外側として描く）・境界・主な道路と鉄道・地名に絞ってある |
| `assets/map/stations.json`（約 490KB） | OpenStreetMap の駅 8,740 件（名前・英語名・中国語名・座標）。**地図には主要駅しか入っていない**ので別に持ち、寄った時（z13 以上）に印として描く |

- **作り方は `tool/build_map.sh`**（`pmtiles` と `tippecanoe` が要る。`brew install pmtiles tippecanoe`）。層と属性の絞り方、z11 で止めた理由（z12 まで入れると約 70MB）もスクリプトの冒頭にある
- **中国語の名前を簡体字に揃えるのに [OpenCC](https://github.com/BYVoid/OpenCC) を使う**（`tool/build_map_names.py`）。入れる手間は無い: スクリプトが一時ディレクトリに venv を作って `pip install --only-binary=:all: opencc==1.2.0`（約 13MB）で入れ、終わったら一時ディレクトリごと消す（Mac にもリポジトリにも残らない）。要るのは python3 と pip がネットに出られることだけ。アプリは変換済みの名前を読むだけで、OpenCC を持ち込まない
- **地図を作り直して層や属性を変えたら、描き方（`lib/features/map/presentation/map_theme.dart`）も直す。** 名前がずれても例外にはならず、その層が黙って描かれなくなる（`test/features/map/map_theme_test.dart` は描き方の側しか見ていない）
- 読み手は自前（`lib/features/map/data/pmtiles.dart`）。公開の PMTiles のパッケージは今の依存と解決できない（理由は同ファイル）
- **地名・駅名は英語・中国語の名前が無ければ描かない**（日本語に落とさない。英語・中国語の画面に日本語を出さないのはユーザーの決定。`map_theme.dart` の「地名の言語」と `Station.labelFor`）
- **中国語の名前は地図を作る時に簡体字へ揃える**（OpenStreetMap の中国語名に繁体字・日本の字体が混ざっている。ユーザーの決定）。日本の字体 → 繁体字 → 簡体字（OpenCC の `jp2t` → `t2s`）の順に通す。**中国語名の無い駅**は、日本語名が仮名を含まなければそれを簡体字にしたもの、仮名（「ケ」「ヶ」「ノ」も）を含めば英語名で描く（どちらも無い 34 駅は描かない）。細かい扱いは `tool/build_map_names.py`
- 配色はアプリ側で持つ（`MapPalette`。`lib/core/theme/app_colors.dart`）。ライト／ダークで描き分ける
- **地図の右下に「© OpenStreetMap」を常に出す**（ODbL の帰属表示。押すと著作権のページ。contributors を付けない理由は `MapAttribution` の注記）。メニューのライセンス一覧にも載せる（`lib/core/licenses/map_data_license.dart`）

## アプリアイコン

元は web の `public/icon.svg`（赤い丸＋白い字の 1 枚）。作りは web の `scripts/lib/icons.ts` に揃えてある（iOS は白いタイルに 0.805 の丸、Android は丸い印だけ（アダプティブは赤の地に字）。理由は `pubspec.yaml` の `flutter_launcher_icons:`）。`assets/icon/` の 3 枚を焼いてから `flutter_launcher_icons` で各プラットフォームのアイコンを生成する。

```bash
# web のリポジトリが隣にある前提
SVG=../tonsoku-frontend-web/public/icon.svg
# 丸を落として字だけにする（web の glyphOnly と同じ）
python3 -c "import re,sys; s=open('$SVG').read(); open('/tmp/glyph.svg','w').write(re.sub(r'<circle\\b[^>]*/>','',s,count=1))"
# iOS: 白い 1024 の中央に直径 824（0.805）の丸を描き直し、同じ大きさの枠に字を重ねる
magick -background none -density 300 /tmp/glyph.svg -resize 824x824 /tmp/glyph_ios.png
magick -size 1024x1024 xc:white -fill '#A7232A' -draw 'circle 512,512 512,100' /tmp/glyph_ios.png -gravity center -composite -alpha off -depth 8 PNG24:assets/icon/icon.png
# Android（アダプティブ非対応の端末）: 角が透明な丸ごとの印
magick -background none -density 300 $SVG -resize 1024x1024 -gravity center -extent 1024x1024 PNG32:assets/icon/icon_android.png
# Android のアダプティブの前景: 透過の地に字だけ（地の赤は設定で敷く）
magick -background none -density 300 /tmp/glyph.svg -resize 1024x1024 -gravity center -extent 1024x1024 PNG32:assets/icon/icon_foreground.png
dart run flutter_launcher_icons
```

**iOS 26 以降のアイコンは `ios/Runner/AppIcon.icon`（Icon Composer の形式）。** 1 枚絵のアイコンだと iOS 26 が既定のガラスの加工を重ね、赤い丸が透けてぼやける。`icon.json` でガラス（`glass`）・透け（`translucency`）・ハイライト（`specular`）・影（`shadow`）を全部切り、地を白で塗って、`Assets/mark.png`（丸と字だけ・透過の地）を 1 枚置いてある。絵を変えた時は `mark.png` も作り直す（`flutter_launcher_icons` はこちらを触らない）。

```bash
magick -size 1024x1024 xc:none -fill '#A7232A' -draw 'circle 512,512 512,100' /tmp/glyph_ios.png -gravity center -composite PNG32:ios/Runner/AppIcon.icon/Assets/mark.png
# 見え方の確認（Xcode 同梱の ictool。Dark も同じように出せる）
"/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" ios/Runner/AppIcon.icon --export-image --output-file /tmp/icon.png --platform iOS --rendition Default --width 180 --height 180 --scale 1
```

**生成したら `ios/Runner.xcodeproj/project.pbxproj` の差分を捨てる。** `flutter_launcher_icons` は `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` まで `AppIcon` に書き換える（アイコン名の設定と取り違えている。本来は `YES`）。

## 起動画面

`flutter_native_splash` で作る（設定は `pubspec.yaml` の `flutter_native_splash:`）。**地色は `AppColors` の `bg`**（ライト `#FAF7F3` / ダーク `#16110F`）で、真ん中にアプリアイコンと同じ印を置く。Android 12 以降は OS の起動画面になり、アダプティブアイコンと同じ作り（赤の地に字）で出る。

絵は `assets/icon/` の 2 枚（アイコンの素材から作る）:

```bash
# iOS / Android 11 以前: 1024 の透過の地の中央に、丸ごとの印を直径 640 で
magick assets/icon/icon_android.png -resize 640x640 -background none -gravity center -extent 1024x1024 PNG32:assets/icon/splash.png
# Android 12 以降: 1152 の中央に字だけを 68%（アダプティブの inset 16% と同じ比）で
magick assets/icon/icon_foreground.png -resize 784x784 -background none -gravity center -extent 1152x1152 PNG32:assets/icon/splash_android12.png
dart run flutter_native_splash:create
```

**生成したら `ios/Runner/Info.plist` の差分を捨てる。** 生成器はファイル全体を字下げし直して書き戻す（中身の変化は `UIStatusBarHidden` の 1 キーだけで、それは既に入れてある）。**`LaunchScreen.storyboard` の地色は手で直さない**（生成のたびに白へ戻る。ダークの出し分けは `color_dark` が作る imageset が持つ。理由は `pubspec.yaml` の注記）。

## リリース

作りは gyumesy-frontend-app と同じ（fastlane・`release-<version>` ブランチから配信・epoch 秒のビルド番号）。

| 文書 | 中身 |
|---|---|
| [docs/release.md](docs/release.md) | 毎リリースやること（lane・ブランチ・提出前の確認） |
| [docs/setup-app.md](docs/setup-app.md) | アプリに 1 回だけのこと（Bundle ID・ASC の枠・署名鍵・Play のアプリ・AdMob） |
| [docs/release-state.md](docs/release-state.md) | **いま何が済んでいて、何が誰待ちか**（ユーザーの手作業の一覧） |
| [docs/secrets.md](docs/secrets.md) | 認証情報・署名鍵の置き場と同期（`scripts/sync-secrets.sh`） |
| [docs/deep-links.md](docs/deep-links.md) | ユニバーサルリンク / App Links（名乗る面・web に置くファイルの中身） |

ストアの掲載情報は `ios/fastlane/metadata/` と `android/fastlane/metadata/`（日本語のみ）。**名前に「松のや」を入れない**（gyumesy は「松屋」で App Store の 4.1(a) を 2 回受けた）。サブタイトル・説明文の冒頭には入れて出し、指摘されたら外す（`docs/release.md` の「提出前の確認」）。非公式であることは説明文に書く。

### ストアの画像

スクリーンショット（iPhone 6.9" / 6.5"・iPad 13"・Play のスマホ / 7" / 10"）・Play のフィーチャー画像とアイコン 512・募集フォームのヘッダーは、**全部 HTML の組版から書き出す**（gyumesy と同じ作り）。**シミュレータで撮らない** ―― 素材が撮った日のまま固まるうえ、機種ごとにシミュレータを立てるとディスクが数十 GB 埋まる。

```bash
node tool/build_store_map.mts        # マップの背景地図と店の印を焼く（地図か store/fixtures/app を変えた時だけ）
python3 tool/build_store_images.py   # 画面（store/source/）→ 額縁（fastlane の置き場）の順に全部書き出す
```

- 額縁（見出し・端末・背景の円）は `store/marketing/*.html`、端末の中の画面は `store/marketing/screens/`（`?d=` で端末の寸法を切り替える）
- 画面の中身は撮った日の配信の写し（`store/fixtures/`）。**見出しに「松のや」を入れない**（理由は `store/marketing/pair12.html`）
- 要るもの: Google Chrome・`magick`（`brew install imagemagick`）・`pmtiles`（`brew install pmtiles`）・web のチェックアウトの `node_modules`（`tool/build_store_map.mts` の冒頭）
