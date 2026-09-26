# リリースの状態（Issue #9）

**何が済んでいて、何が誰待ちか**を 1 箇所に置く。

- 毎リリースやること → `docs/release.md`
- アプリに 1 回だけのこと（手順の詳細） → `docs/setup-app.md`
- 認証情報の置き場 → `docs/secrets.md`
- ユニバーサルリンク / App Links → `docs/deep-links.md`

## 済んでいるもの

| | 状態 |
|---|---|
| 起動画面 | `flutter_native_splash`（`pubspec.yaml`）。地色は `AppColors` の `bg`（ライト `#FAF7F3` / ダーク `#16110F`）、Android 12 以降はアダプティブアイコンと同じ作り（赤の丸＋字） |
| fastlane | `ios/fastlane` と `android/fastlane`。gyumesy と同じ lane・見張り（`release-` ブランチ・未コミット・debug 鍵） |
| 掲載情報（ja） | `ios/fastlane/metadata/ja/` と `android/fastlane/metadata/android/ja-JP/`。**名前「とん速」には「松のや」を入れない**（サブタイトル・説明文の冒頭の扱いは `docs/release.md` の「提出前の確認」） |
| ストアの画像 | `tool/build_store_images.py`（#41。iPhone・iPad・Play・フィーチャー画像・アイコン 512） |
| 審査メモ | `ios/fastlane/metadata/review_information/notes.txt` |
| 年齢レーティング | `ios/fastlane/rating_config.json`（gyumesy の値＋`advertising: true`） |
| 輸出コンプライアンス | `Info.plist` の `ITSAppUsesNonExemptEncryption = false`（gyumesy の #39 を写した） |
| **Android アップロード鍵** | **作成済み**（2026-09-26。PKCS12・10000 日。指紋は `docs/setup-app.md` の「済んだもの（とん速）」）。`gdrive:gyumesy-secrets/repo/tonsoku-frontend-app/` に退避済み |
| リリース署名の設定 | `android/app/build.gradle.kts`。**鍵が無い環境では debug 鍵のまま**。配信の lane は鍵が無いと止まる |
| ユニバーサルリンク / App Links（アプリ側） | entitlement（`applinks:ton-soku.com`）・intent-filter（`autoVerify`）・受け口（`_listenAppLinks`） |
| web 側 | AASA（web #144・#148）・`app-ads.txt`（web #156）は本番に出ている |
| AdMob | アプリ 2 つ・広告ユニット 6 つを作成済み。ID はリポジトリに入っている（発行者 `pub-7838125849960397`） |
| 広告を外す課金（アプリ側。#42） | 購入・復元・起動時の突き合わせ・導線。商品の定義は `iap_products.yaml`、登録の lane は `register_iap` |

**掲載は日本語だけ**（gyumesy と同じ。en / zh の掲載情報は置かない）。

## ストアの今の状態（2026-09-26 に API で読んで確かめた）

| | 状態 |
|---|---|
| iOS の Bundle ID `com.gyumesy.tonsoku` | **まだ無い** |
| App Store Connect のアプリ枠 | **まだ無い** |
| Play のアプリ `com.gyumesy.tonsoku` | **取れない**（`Invalid request`。アプリが無いか、サービスアカウントに権限が無い。API では区別できない） |

## 残りの手順（上から順に。誰がやるかを書く）

**先例は gyumesy**（`docs/setup-app.md`・git の履歴）。**lane と API は Claude が叩く**
（あちらでも Bundle ID・アプリ枠・審査連絡先・TestFlight のグループ・アップロード鍵は Claude が
作った）。**ユーザーの手が要るのは、UI にしか口が無いものと、契約・支払いに同意するものだけ。**
不可逆な登録（Bundle ID・アプリ枠・課金の商品）は、叩く直前にユーザーに一言断る。

| # | やること | 誰が | 手段 |
|---|---|---|---|
| 1 | fastlane の gem を入れる | Claude | `mise exec -- bundle install`（`vendor/bundle`） |
| 2 | iOS の Bundle ID（Push・Associated Domains 込み） | Claude | `ios register_app_id` |
| 3 | App Store Connect のアプリ枠 | Claude | `ios create_app`（名前「とん速」が取られていたらユーザーが決める） |
| 4 | App Store ID を infra へ | Claude | tonsoku-infra-terraform のセッションへ連絡 |
| 5 | 審査連絡先 | Claude | API（`appStoreReviewDetails`。連絡先は牛めしレーダー・gyumesy と同じ値を ASC から写す） |
| 6 | TestFlight の内部グループ（全ビルド自動） | Claude | API（`betaGroups` / `betaTesters`。gyumesy #39 と同じ） |
| 7 | 価格（無料）・販売地域・年齢レーティング | Claude | API（three の setup-app.md §4 のレシピ。販売地域は全世界＝訪日客のため。gyumesy と同じ判断） |
| 8 | **App Privacy**（広告・位置情報・通知・計測・トラッキング） | **ユーザー** | ASC の UI のみ（中身は `docs/setup-app.md` の「App Privacy」） |
| 9 | **有料 App 契約**（契約・銀行口座・税務） | **ユーザー** | ASC の UI のみ（Account Holder） |
| 10 | **Play のアプリを作る**（`com.gyumesy.tonsoku`。変更不可）・**サービスアカウントに権限** | **ユーザー** | Play Console の UI のみ |
| 11 | **Play の「アプリのコンテンツ」**: 広告あり・広告 ID は使う・対象年齢・コンテンツレーティング（IARC）・プライバシーポリシー URL・販売地域 | **ユーザー** | Play Console の UI のみ |
| 12 | Play のデータ セーフティ | Claude | API（`dataSafety`。three と同じ） |
| 13 | **Play のお支払いプロファイルの連携** | **ユーザー** | Play Console の UI のみ（管理者） |
| 14 | 署名の指紋を infra（Firebase）と web（`assetlinks.json`）へ | Claude | 各セッションへ連絡（Play のアプリ署名鍵の指紋は 10 の後に Play から取る） |
| 15 | **AdMob の同意メッセージ（UMP）を公開** | **ユーザー** | AdMob の UI のみ |
| 16 | 初回のテスト配信: `release-1.0.0` → `android alpha draft:true`（初回だけ draft）→ `ios beta` | Claude | lane |
| 17 | 課金の商品を登録 | Claude | `register_iap`（iOS は 3・9 の後、Android は 13・16 の後。dry-run を見せてから apply） |
| 18 | **課金の価格 ¥550・審査用スクショ（iOS）／商品の有効化・ライセンステスター（Play）** | **ユーザー** | UI のみ（`docs/setup-app.md` の「アプリ内課金の商品」） |
| 19 | 公開後に AdMob の各アプリを「ストアに追加」で紐づける | **ユーザー** | AdMob の UI のみ |

## 他のセッションへ頼むもの

| 相手 | 頼むこと | いつ |
|---|---|---|
| tonsoku-infra-terraform | App Store ID（上の 4）・Android の指紋（上の 14） | 3 の後・10 の後 |
| tonsoku-frontend-web | `/.well-known/assetlinks.json`（上の 14） | 10 の後 |
