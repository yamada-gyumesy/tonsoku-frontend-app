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
| `python3 tool/build_licenses.py` | ライセンス表記から外すパッケージ（配布物に入らないもの）の一覧を作り直す。依存を変えたら回す（CI が差分を見る） |

**生成物（`*.freezed.dart` / `*.g.dart`）はリポジトリにコミットする。** CI が生成し直して差分が出ないことを確認する。

CI は `.tool-versions` から Flutter の版を読んで固定し、`flutter pub get --enforce-lockfile` で `pubspec.lock` のとおりに解決する。

## ディレクトリ構成

```
lib/
  core/
    cdn/        # 配信データのパス解決と取得（stale-while-revalidate）
    config/     # 環境設定
    i18n/       # ロケール定義・UI固定文言
    network/    # CDN クライアント
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
| `app/shop.json` / `app/limited.json` / `app/version.json` | マップ向け（店舗と店舗限定の取扱店） |

**形は gyumesy とほぼ同じ**だが、記事本体の置き場（gyumesy は `articles/{slug}/index.md`）と、`null` を出す鍵がある点が違う（`lib/shared/models/article_meta.dart`）。

**配信データの形は CDN の実物を見る**（`curl -s https://cdn.ton-soku.com/articles/feed.json | head`）。`tonsoku-backend-batch/output/` は R2 配信が始まる前の古い形なので見ないこと（web の CLAUDE.md と同じ注意）。

## 書体

**日本語は Klee One、英語・中国語は Noto Sans JP**（web と同じ使い分け）。実体は web が npm で持っている配布物から `tool/build_fonts.py` が作る（web 側で `yarn install` 済みであること）。

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
