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
| 掲載情報（ja） | `ios/fastlane/metadata/ja/` と `android/fastlane/metadata/android/ja-JP/`。**名前「とん速」には「松のや」を入れない**（サブタイトル・説明文の冒頭の扱いは `docs/release.md` の「提出前の確認」）。説明文に非公認ファンメディアの断り（web の「とん速とは」と同じ文） |
| 審査メモ | `ios/fastlane/metadata/review_information/notes.txt` |
| 年齢レーティング | `ios/fastlane/rating_config.json`（gyumesy の値＋`advertising: true`） |
| リリース署名の設定 | `android/app/build.gradle.kts`。**鍵が無い環境では debug 鍵のまま**（鍵を持たない人でもビルドできるように）。配信の lane は鍵が無いと止まる |
| 鍵の同期 | `scripts/sync-secrets.sh`（`gdrive:gyumesy-secrets/repo/tonsoku-frontend-app/`） |
| ユニバーサルリンク / App Links（アプリ側） | entitlement（`applinks:ton-soku.com`）・intent-filter（`autoVerify`）・受け口（`_listenAppLinks`） |
| 広告を外す課金（アプリ側。Issue #42） | 購入・復元・起動時の突き合わせ・導線（メニュー / マップ）。商品の定義は `iap_products.yaml`、登録の lane は `register_iap`（iOS / Android）。審査メモにも書いた |

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
8. **AdMob**: アプリ 2 つ・広告ユニット 6 つは作成済みで、ID もリポジトリに入っている
   （発行者 `pub-7838125849960397`。README の「広告」）。審査に出す前に残るもの:
   - 同意（UMP）の GDPR メッセージを AdMob の「プライバシーとメッセージ」で公開する（ユーザー）
   - 発行者 ID を web の `app-ads.txt` に載せる（web の作業）
   - ストアに公開した後、AdMob の各アプリを「ストアに追加」で紐づける（ユーザー）
9. **広告を外す課金**（`docs/setup-app.md` の「アプリ内課金の商品」。**lane で済むことと
   Web UI でしかできないことを分けてある**）:
   - Web UI（先に）: **ASC の有料 App 契約**（契約・銀行口座・税務。Account Holder）／
     **Play のお支払いプロファイルの連携**（管理者）
   - lane: `cd ios && mise exec -- bundle exec fastlane ios register_iap`（dry-run）→ `apply:true`
     （ASC のアプリ枠＝上の 3 が先）
   - lane: `cd android && mise exec -- bundle exec fastlane android register_iap`（dry-run）→
     `apply:true`（**課金の入ったビルドを Play に 1 度上げてから**＝下の 10 の alpha の後）
   - Web UI（後で）: **ASC で価格 ¥550 を付ける**・**審査用のスクリーンショット**／
     **Play で商品を有効にする**・**ライセンステスターの登録**
   - 最初の審査は、アプリの版と一緒に商品を審査に加える（Web UI。`docs/release.md` の「提出前の確認」）
10. **初回のテスト配信**: `release-1.0.0` を切って
   `cd android && mise exec -- bundle exec fastlane android alpha draft:true`（**初回だけ draft**）→
   `cd ios && mise exec -- bundle exec fastlane ios beta`

## 他のセッションへ頼むもの

| 相手 | 頼むこと | いつ |
|---|---|---|
| tonsoku-frontend-web | `/.well-known/apple-app-site-association` を置く（中身は `docs/deep-links.md`。`_headers` で `application/json`） | **済み**（web #144・#148。本番に出ている） |
| tonsoku-frontend-web | `/.well-known/assetlinks.json` を置く | 上の 7 の指紋が出てから |
| tonsoku-frontend-web | `app-ads.txt` | **済み**（web #156。本番に出ている） |
| tonsoku-infra-terraform | App Store ID・Android の指紋 | 上の 4・7 の後 |

## まだ作っていないもの

- **iOS の ATT（トラッキングの許可）。** Issue #5 で入れた（`NSUserTrackingUsageDescription` は
  `Info.plist` にある）。App Privacy で「トラッキング」を申告する
