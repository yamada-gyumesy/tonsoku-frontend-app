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
| iOS の Bundle ID `com.gyumesy.tonsoku` | **登録済み**（2026-09-26。id=`2QM97U5BM5`。Push・Associated Domains 有効） |
| App Store Connect のアプリ枠 | **まだ無い**（API では作れない。下の 3） |
| 開発用プロファイル | `iOS Team Provisioning Profile: com.gyumesy.tonsoku`（アーカイブで作られた。署名つきのアーカイブは通る） |
| 配布用の署名 | **この Mac で ipa を書き出せない**（Xcode にアカウントが無く、配布用の証明書も無い。下の 3b） |
| Android のリリース署名 | `flutter build appbundle --release` の AAB がアップロード鍵で署名されていることを確かめた（SHA-256 一致） |
| Play のアプリ `com.gyumesy.tonsoku` | **取れない**（`Invalid request`。アプリが無いか、サービスアカウントに権限が無い。API では区別できない） |

## 残りの手順（上から順に。誰がやるかを書く）

**先例は gyumesy**（`docs/setup-app.md`・git の履歴）。**lane と API は Claude が叩く**
（あちらでも Bundle ID・アプリ枠・審査連絡先・TestFlight のグループ・アップロード鍵は Claude が
作った）。**ユーザーの手が要るのは、UI にしか口が無いものと、契約・支払いに同意するものだけ。**
不可逆な登録（Bundle ID・アプリ枠・課金の商品）は、叩く直前にユーザーに一言断る。

| # | やること | 誰が | 手段 |
|---|---|---|---|
| 1 | ~~fastlane の gem を入れる~~ **済み** | Claude | `bundle install` は `io-console` のビルドが Command Line Tools の SDK で落ちたので、Gemfile.lock が同じ gyumesy の `vendor/bundle` を写した |
| 2 | ~~iOS の Bundle ID（Push・Associated Domains 込み）~~ **済み** | Claude | `ios register_app_id` |
| 3 | **App Store Connect のアプリ枠**（名前「とん速」・Bundle ID `com.gyumesy.tonsoku`・SKU `com.gyumesy.tonsoku`・主言語 日本語） | **ユーザー** | **ASC の UI のみ**。`ios create_app` は `The resource 'apps' does not allow 'CREATE'` で弾かれた（2026-09-26 実測。gyumesy の「API で作れる見込み」は確かめられていなかった。gyumesy も枠は手で作っている） |
| 3b | **Xcode に `gyumesy@icloud.com` でサインイン**（Xcode → Settings → Accounts） | **ユーザー** | 配布の署名（クラウド署名）に要る。無いと `ios beta` の ipa の書き出しが `No Accounts` / `No signing certificate "iOS Distribution"` で落ちる（2026-09-26 実測）。API 鍵でのクラウド署名は `Cloud signing permission error`（鍵の権限が足りない） |
| 4 | App Store ID を infra へ | Claude | tonsoku-infra-terraform のセッションへ連絡 |
| 5 | 審査連絡先 | Claude | API（`appStoreReviewDetails`。連絡先は **gyumesy の審査連絡先を ASC から写す**） |
| 6 | TestFlight の内部グループ（全ビルド自動） | Claude | API（`betaGroups` / `betaTesters`。gyumesy #39 と同じ） |
| 7 | 価格（無料）・販売地域・年齢レーティング | Claude | API（three の setup-app.md §4 のレシピ。販売地域は全世界＝訪日客のため。gyumesy と同じ判断） |
| 8 | **App Privacy**（広告・位置情報・通知・計測・トラッキング） | **ユーザー** | ASC の UI のみ（中身は `docs/setup-app.md` の「App Privacy」） |
| 9 | **有料 App 契約**（契約・銀行口座・税務） | **ユーザー** | ASC の UI のみ（Account Holder） |
| 10 | **Play のアプリを作る**（`com.gyumesy.tonsoku`。変更不可）・**サービスアカウントに権限** | **ユーザー** | Play Console の UI のみ |
| 11 | **Play の「アプリのコンテンツ」**（広告あり・広告 ID は使う・対象年齢・コンテンツレーティング（IARC）・プライバシーポリシー URL）と、**トラックの販売国** | **ユーザー** | Play Console の UI のみ（販売国はアプリのコンテンツではなく各トラックの設定） |
| 12 | Play のデータ セーフティ | Claude | API（`dataSafety`。three と同じ） |
| 13 | **Play のお支払いプロファイルの連携** | **ユーザー** | Play Console の UI のみ（管理者） |
| 14 | ~~**アップロード鍵**の指紋を infra（Firebase）と web（`assetlinks.json`）へ~~ **済み** | Claude | infra #34（Firebase に登録済み）・web #162（`assetlinks.json` を main に入れた。本番はデプロイ待ち） |
| 15 | **AdMob の同意メッセージ（UMP）を公開** | **ユーザー** | AdMob の UI のみ |
| 16 | 初回のテスト配信: `release-1.0.0` → `android alpha draft:true`（初回だけ draft）→ `ios beta` | Claude | lane |
| 16b | **アプリ署名鍵**の指紋を infra と web へ | Claude | **最初の AAB を上げた後**（16 の後）に Play App Signing へ自動で登録されて出る。Play Console の「アプリの完全性」か API（`generatedapks`）で取り、各セッションへ連絡。**これが入らないと、ストアから入れた端末で App Links が通らない** |
| 17 | 課金の商品を登録 | Claude | `register_iap`（iOS は 3・9 の後、Android は 13・16 の後。dry-run を見せてから apply） |
| 18 | **課金の価格 ¥550・審査用スクショ（iOS）／商品の有効化・ライセンステスター（Play）** | **ユーザー** | UI のみ（`docs/setup-app.md` の「アプリ内課金の商品」） |
| 19 | 公開後に AdMob の各アプリを「ストアに追加」で紐づける | **ユーザー** | AdMob の UI のみ |

## 他のセッションへ頼むもの

| 相手 | 頼むこと | いつ |
|---|---|---|
| tonsoku-infra-terraform | App Store ID（上の 4）・Play のアプリ署名鍵の指紋（上の 16b）。アップロード鍵のぶんは済み（infra #34） | 3 の後・16 の後 |
| tonsoku-frontend-web | `assetlinks.json` に Play のアプリ署名鍵の指紋を足す（上の 16b）。アップロード鍵のぶんは済み（web #162） | 16 の後 |
