# リリースの状態（Issue #9）

**何が済んでいて、何が誰待ちか**を 1 箇所に置く。

- 毎リリースやること → `docs/release.md`
- アプリに 1 回だけのこと（手順の詳細） → `docs/setup-app.md`
- 認証情報の置き場 → `docs/secrets.md`
- ユニバーサルリンク / App Links → `docs/deep-links.md`

## 済んでいるもの（リポジトリ側）

| | 状態 |
|---|---|
| 起動画面 | `flutter_native_splash`（`pubspec.yaml`）。地色は `AppColors` の `bg`（ライト `#FAF7F3` / ダーク `#16110F`）、Android 12 以降はアダプティブアイコンと同じ作り（赤の丸＋字） |
| fastlane | `ios/fastlane` と `android/fastlane`。gyumesy と同じ lane・見張り（`release-` ブランチ・未コミット・debug 鍵） |
| 掲載情報（ja） | `ios/fastlane/metadata/ja/` と `android/fastlane/metadata/android/ja-JP/`。**名前「とん速」・サブタイトルに「松のや」を入れず**、説明文の冒頭に非公認ファンメディアの断り（web の「とん速とは」と同じ文） |
| 審査メモ | `ios/fastlane/metadata/review_information/notes.txt` |
| 年齢レーティング | `ios/fastlane/rating_config.json`（gyumesy の値＋`advertising: true`） |
| リリース署名の設定 | `android/app/build.gradle.kts`。**鍵が無い環境では debug 鍵のまま**（鍵を持たない人でもビルドできるように）。配信の lane は鍵が無いと止まる |
| 鍵の同期 | `scripts/sync-secrets.sh`（`gdrive:gyumesy-secrets/repo/tonsoku-frontend-app/`） |
| ユニバーサルリンク / App Links（アプリ側） | entitlement（`applinks:ton-soku.com`）・intent-filter（`autoVerify`）・受け口（`_listenAppLinks`） |

**掲載は日本語だけ**（gyumesy と同じ。en / zh の掲載情報は置かない）。App Store Connect は
**掲載言語ごとにスクリーンショットを 1 枚以上**要求するので、増やすならスクショもセットで要る。

## ユーザーにしかできないもの（上から順に）

**認証情報を扱う・アカウントを作る・同意する操作**なので、Claude はやらない。
lane を叩くものは「叩いてよい」と言ってもらえれば手順どおりに進められるが、
**鍵のパスワードを決める・コンソールで申告に答えるのは本人**。

1. **Android のアップロード鍵を作る**（`docs/setup-app.md` の「アップロード署名鍵」）。
   `android/keystore/upload.jks` と `android/key.properties` を置き、
   `bash scripts/sync-secrets.sh upload` で退避する。**二度と作り直さない**
2. **iOS の Bundle ID を登録する**: `cd ios && mise exec -- bundle exec fastlane ios register_app_id`
   （プッシュと Associated Domains もまとめて有効になる。既にあれば作り直さない）
3. **ASC のアプリ枠を作る**: `cd ios && mise exec -- bundle exec fastlane ios create_app`。
   名前「とん速」が取られていたら落ちるので、その時は名前を決める
4. **App Store ID を tonsoku-infra-terraform のセッションへ伝える**（Firebase の iOS アプリ登録に入れる）
5. **ASC の UI で入れるもの**: 審査連絡先（App Review Information。個人の連絡先なので
   リポジトリに置かない）・**App Privacy**（広告 SDK・位置情報・FCM。`docs/setup-app.md`）・
   価格（無料）・配信地域・TestFlight の内部グループ
6. **Play Console でアプリを作る**（`com.gyumesy.tonsoku`。**変更不可**）。
   サービスアカウントにこのアプリへの権限を付ける。**広告「あり」**・データ セーフティ・
   対象年齢・コンテンツレーティング（IARC）・販売地域を UI で答える
7. **署名の指紋を 2 か所へ**: アップロード鍵の SHA-1 / SHA-256 と、Play の「アプリの署名」の
   SHA-256（Play でアプリを作った後に出る）を
   - tonsoku-infra-terraform のセッションへ（Firebase の Android アプリ。**Console で入れない**）
   - tonsoku-frontend-web のセッションへ（`assetlinks.json`。`docs/deep-links.md`）
8. **AdMob にアプリを登録し、広告ユニットを作り、ID を差し替える**（iOS / Android。枠ごと）。
   **いまのリポジトリは本番の ID が全部空で、release ビルドは広告を 1 つも出さない**（Issue #5）。
   **このまま出すと、広告の出ない版を「広告あり」で申告することになる**ので、審査に出す前に必ず:
   - アプリ ID 2 つ: `ios/Runner/Info.plist` の `GADApplicationIdentifier` と
     `android/app/src/main/AndroidManifest.xml` の `com.google.android.gms.ads.APPLICATION_ID`
     （いまは Google のテスト用）
   - 広告ユニット ID 6 つ（アンカー / 記事 / マップのリワード × iOS / Android）:
     `lib/core/config/ad_config.dart` の `productionIos` / `productionAndroid`（いまは空）
   - **アプリ ID だけ・ユニット ID だけでは配信されない**（両方そろえる）
   - 発行者 ID を web の `app-ads.txt` に載せる（web の作業）
9. **初回のテスト配信**: `release-1.0.0` を切って
   `cd android && mise exec -- bundle exec fastlane android alpha draft:true`（**初回だけ draft**）→
   `cd ios && mise exec -- bundle exec fastlane ios beta`

## 他のセッションへ頼むもの

| 相手 | 頼むこと | いつ |
|---|---|---|
| tonsoku-frontend-web | `/.well-known/apple-app-site-association` を置く（中身は `docs/deep-links.md`。`_headers` で `application/json`） | **いつでも**（appID は確定している） |
| tonsoku-frontend-web | `/.well-known/assetlinks.json` を置く | 上の 7 の指紋が出てから |
| tonsoku-frontend-web | `app-ads.txt` | 上の 8 の後 |
| tonsoku-infra-terraform | App Store ID・Android の指紋 | 上の 4・7 の後 |

## まだ作っていないもの

- **ストアのスクリーンショット・Play の画像（アイコン 512・フィーチャーグラフィック 1024×500）。**
  gyumesy は `store/marketing/`（HTML の組版）→ `tool/build_store_images.py`（headless Chrome で
  寸法ちょうどに書き出し）で作っている。**実機で撮らず組版で作る**のは、素材が古くならない・
  iPad 判を iPad として組めるから（gyumesy の #82）。**とん速も同じ仕組みを写す**（別 Issue）。
  - **端末は 3 系統**: iPhone 6.9"（1290×2796）/ 6.5"（1284×2778）/ **iPad 13"（2048×2732）**。
    `TARGETED_DEVICE_FAMILY` が `"1,2"`（iPad でも動く）なので **iPad のぶんも要る**
    （gyumesy の初回提出が `is not in valid state` で落ちた原因の 1 つ）。**審査端末は iPad のことがある**
  - **見出しに「松のや」を入れない**（gyumesy は 1 枚目・4 枚目の見出しの「松屋」で 4.1(a)）
  - マップの見本はユーザーの手元の 2 枚（`~/Desktop/map_20260926_005048.png` /
    `~/Desktop/map_20260926_005124.png`。web でも使う予定のもの）を参考にできる
- **広告の本番 ID（上の 8）。** 実装（Issue #5）は入っているが、本番の ID が空なので release は
  広告を出さない。審査メモ・`rating_config.json`・App Privacy は広告が出る前提で書いてある。
  **ID を入れずに出すなら、3 つとも「広告なし」に直す**（申告と中身を食い違わせない）
- **iOS の ATT（トラッキングの許可）。** Issue #5 で入れた（`NSUserTrackingUsageDescription` は
  `Info.plist` にある）。App Privacy で「トラッキング」を申告する
