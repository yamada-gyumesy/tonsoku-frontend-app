# アプリの初期設定（アプリに 1 回だけ）

**毎リリースでやることは `docs/release.md`。ここは「一度きり」だけ。**
**いま何が済んでいて何が誰待ちか**は `docs/release-state.md`。

判定基準は **「次の 1.0.1 でも、また同じことをやるか？」**。
はい → `release.md` / いいえ → ここ。

**gyumesy-frontend-app の `docs/setup-app.md` を写し、値をとん速に替えた。** 手順と落とし穴は
あちらで実際に踏んだもの（「gyumesy では」と書いてあるものはあちらの実測）。

---

## 自動化できるもの / できないもの

**「API 非対応で手動 UI のみ」という言い伝えは、鵜呑みにしない。** gyumesy の Issue #7 は
「App Store Connect のアプリ枠 / Play のアプリ作成は API 非対応」と書いていたが、
**Bundle ID も ASC のアプリ枠も API で作れた**。**まず叩いてみること。**

| | 手段 |
|---|---|
| **iOS の Bundle ID** | ✅ **API**（`fastlane ios register_app_id`） |
| iOS の Push / Associated Domains capability | ✅ **API**（同 lane がまとめて有効化） |
| App Store Connect のアプリ枠 | ✅ **API**（`fastlane ios create_app`） |
| Play のアプリ作成 | ❌ UI のみ。**package name は初回確定で変更不可** |
| 価格・販売地域 | iOS ✅ API / Android ❌ UI |
| 年齢・コンテンツレーティング | iOS ✅（`ios/fastlane/rating_config.json`） / Android ❌ UI のみ（IARC） |
| データ収集の申告（App Privacy） | iOS ❌ **ASC の UI のみ** / Android ✅ API |
| 広告の有無・対象年齢・プライバシーポリシー URL | iOS ✅ / Android ❌ **UI のみ** |
| アプリ内課金の商品（ID・表示名・販売地域） | ✅ **lane**（`register_iap`。下の「アプリ内課金の商品」） |
| アプリ内課金の価格 | iOS ❌ **Web UI**（lane で付けない。理由は同節） / Android ✅ lane |
| アプリ内課金の有効化（販売開始） | iOS: 審査を通ると売られる / Android ❌ **Play Console**（lane に入れない） |
| 有料 App 契約・お支払いプロファイル・ライセンステスター | ❌ **UI のみ** |

**lane と API は Claude が叩く**（gyumesy と同じ。Bundle ID・アプリ枠・審査連絡先・
TestFlight のグループ・アップロード鍵は、あちらでも Claude が作った）。認証情報は
`~/.config/gyumesy/` にあり（`docs/secrets.md`）、**中身を表示・送信しない**。
**ユーザーの手が要るのは、上の表で ❌（UI のみ）のものと、契約・支払いに同意するものだけ。**

---

## iOS

### Bundle ID の登録

```bash
cd ios && mise exec -- bundle exec fastlane ios register_app_id
```

**やり直しが効かない。** 一度使った Bundle ID は再利用できない。

- **Push と Associated Domains を Bundle ID 側でも有効にする。** `Runner.entitlements` に
  `aps-environment`（通知）と `com.apple.developer.associated-domains`（ユニバーサル
  リンク）を持っているので、Bundle ID 側が無効だと profile と食い違って TestFlight の
  ビルドが `profile doesn't include the ... capability` で落ちる。上の lane がまとめてやる
  （**Associated Domains は gyumesy の lane には無く、とん速で足した**）
- **Capability を変えたら profile を作り直す。** 変えた後に作り直さないと、同じ食い違いが起きる

> #### ⛔ `produce` は使えない
>
> `fastlane produce` は Developer Portal を **Apple ID のセッション**で叩く作りで、
> **ASC の API 鍵を受け付けない**（`Could not find option 'api_key'`）。
> `Spaceship::ConnectAPI` を直接使えば API 鍵で通る（lane はそうしている）。
>
> #### ⛔ `BundleId#capabilities` というメソッドは無い
>
> 取りに行く口は **`get_capabilities`**。属性のほうは `bundle_id_capabilities`
> だが、**`find` では埋まらない**（`includes` を渡した時だけ）。

### App Store Connect のアプリ枠

```bash
cd ios && mise exec -- bundle exec fastlane ios create_app
```

**手で作らない**（gyumesy は手で作ってしまった。API で作っても同じ枠ができる）。

- **Bundle ID が先。** 枠は Bundle ID に紐づくので、無いと作れない
- **SKU は後から変えられない。** bundle id と同じにしておくと迷わない（lane がそうする）
- **名前は「とん速」**（`ios/fastlane/Fastfile` の `APP_NAME`）。**「松のや」を入れない**
  （gyumesy は「松屋」の語で 4.1(a) を 2 回受けた）。**名前は App Store 全体で一意**なので、
  取られていたら lane が落ちる。その時は**ユーザーが決める**（勝手に語を足さない）
- `version_string` が最初のバージョン。作った枠は `PREPARE_FOR_SUBMISSION` で始まる
- `primary_locale` は `ja`

**作ったら App Store ID（数字の `id`）を tonsoku-infra-terraform のセッションに伝える**
（Firebase の iOS アプリ登録に入れる。`docs/release-state.md` の「残りの手順」の 4）。

### 審査連絡先（`appStoreReviewDetail`）

**これが無いと `fastlane ios metadata` が `No data` で落ちる。** `deliver` は
掲載情報を入れるだけの時でも必ず `fetch_app_store_review_detail` を通るので、
審査に出す前から必要になる（`deliver/upload_metadata.rb:752`）。

作られるのは**版ごとではなくアプリの最初の版に 1 回**。**API で作る**
（`POST /v1/appStoreReviewDetails` に `appStoreVersion` を紐づける。gyumesy と同じ）。

- `contactFirstName` / `contactLastName` / `contactPhone` / `contactEmail` は**個人の連絡先**。
  **gyumesy の審査連絡先（ASC にある）を API で写す**（とん速の手本は gyumesy。gyumesy の値は
  牛めしレーダーと同じ）。
  **リポジトリに置かない**（ファイルが無い項目は `deliver` が送らない）
- `demoAccountRequired` は `false`（ログインが無いアプリなので）
- `notes` は `ios/fastlane/metadata/review_information/notes.txt` が持つ（`deliver` が送る）

### App Privacy（データ収集の申告）

**ASC の UI のみ。** とん速は gyumesy と違って**広告（AdMob）**と**位置情報**を持つので、
gyumesy の申告を写さない。**広告の実装（Issue #5）が入ってから、その SDK が集めるものに
合わせて答える**（AdMob の「データの種類」の開示に従う。ATT を出すなら「トラッキング」も）。

- 位置情報: マップの「現在地」で使うが**端末の外へ送らない**（地図を寄せるだけ）
- 通知: FCM のトークン（デバイス ID 相当）
- 計測: GA4（Firebase Analytics。#29 で入れた）
- 購入: 広告を外す課金（#43）の記録は端末とストアの間だけで、こちらへは送らない

### TestFlight の配信先（ベータグループ）

**グループが 1 つも無いと、ビルドを上げても誰にも降らない。** ASC は勝手には
作らない。アプリに 1 回だけ作る。

- **内部グループ**（`isInternalGroup: true`）のテスターは **ASC のユーザー**。
  外部テスターと違い Beta App Review が要らないので、開発中はこちらだけでよい
- **`hasAccessToAllBuilds: true` にする。** **内部グループはビルドに紐づけられない**
  （`relationships/builds` に POST すると `Cannot add internal group to a build`）ので、
  false にすると新しいビルドを配る手段が API に無くなる
- 追加したテスターは `INVITED` から始まる。**招待メールを受けるまで端末には出ない**

`POST /v1/betaGroups` → `POST /v1/betaTesters`（`betaGroups` を関連付け）で作れる。

---

## Android

### アップロード署名鍵

**初回だけ。以後絶対に作り直さない。** 作り直すと Play へ上げられなくなる。

**手元に無い時は「未生成」ではなく「未受領」を疑う。** 先に Drive を見る:

```bash
bash scripts/sync-secrets.sh status   # repo/tonsoku-frontend-app/ に鍵があるか
bash scripts/sync-secrets.sh download # あれば取ってくる
```

**本当に無い時だけ**作る（gyumesy と同じく Claude が作る。パスワードは乱数で作って
`key.properties` にだけ書き、**画面に出さない**）:

```bash
keytool -genkeypair -keystore android/keystore/upload.jks -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload \
  -storepass "$PW" -keypass "$PW" -dname "CN=Tonsoku, C=JP"
```

- **PKCS12 で作る。** JKS は旧形式で、ビルドのたびに移行を促す警告が出る
- `android/key.properties` に 4 つ（`storeFile` / `storePassword` / `keyAlias` /
  `keyPassword`）を書く。`storeFile` は **`android/app` から見た相対パス**
  （`../keystore/upload.jks`）
- **どちらも `.gitignore` 済みであること**を確かめてから作る
  （`git check-ignore -v android/key.properties android/keystore/`）
- 作ったら `bash scripts/sync-secrets.sh upload` で退避する

**鍵が無い環境でも `flutter build apk --release` は通る**（debug 鍵に落ちる。
`android/app/build.gradle.kts`）。**配信の lane は鍵が無いと止まる**
（`ensure_release_signing`）ので、debug 鍵のまま Play に上がることは無い。

**指紋を取って 2 か所へ渡す:**

```bash
keytool -list -v -keystore android/keystore/upload.jks -alias upload | grep -E "SHA1:|SHA256:"
```

- **Firebase の Android アプリへ**（tonsoku-infra-terraform のセッションに依頼。
  **Console で入れると次の apply が消す**ので Terraform で）
- **web の `assetlinks.json` へ**（App Links。`docs/deep-links.md`）

**Play App Signing を使うと、配布される APK は Google が持つ「アプリ署名鍵」で
署名し直される。** そちらの指紋は**最初の AAB を上げた後**（アプリを作っただけでは
出ない。上げた時に Play App Signing へ自動で登録される）に、Play Console の
「アプリの完全性」か API（`generatedapks`）で取れる。**`assetlinks.json` には両方要る**（ストアから入れた端末は
アプリ署名鍵、手元で入れた端末はアップロード鍵で署名されている）。

### 済んだもの（とん速）

| | 値 |
|---|---|
| アップロード鍵 | `android/keystore/upload.jks`（PKCS12・10000 日。2026-09-26 作成、Drive に退避済み） |
| SHA-1 | `20:C7:2F:99:BA:A5:0F:46:EB:34:16:21:04:94:47:18:2B:1A:42:4B` |
| SHA-256 | `28:0E:8A:4D:50:7B:8C:B6:0C:89:A1:5E:92:84:B9:87:74:E6:60:9D:65:57:B4:3D:A9:D3:68:2F:CB:98:2B:7A` |

### Play のアプリ

**UI のみ。** `package name`（`com.gyumesy.tonsoku`）は**初回確定で変更不可**。

作った後、**Play Console の「ユーザーと権限」でサービスアカウントに
このアプリへのアクセスを付ける**こと。付いていないと `supply` が
`Invalid request` で弾かれ、**「アプリが無い」のか「権限が無い」のか
API からは区別できない**。

UI でしか入れられない申告（gyumesy と違うところだけ）:

- **広告: 「含まれている」**（AdMob）。**`AD_ID` 権限を消さない**（gyumesy は広告を持たないので
  消しているが、AdMob は広告 ID を使う。消すと広告の配信が制限される）
- 対象年齢・コンテンツレーティング（IARC）

**データ セーフティは API で入れる**（`dataSafety`。three と同じ。上の表）。中身は位置情報（端末内のみ）・
デバイス ID（FCM）・広告 SDK が集めるもの・計測（GA4）

---

## アプリ内課金の商品（広告を外す。Issue #42）

**three-frontend-flutter の `register_iap`（§3-G）を写した。** あちらは自動更新サブスクなので、
**買い切り（非消耗型）の API に置き換えた**（iOS: ASC の `inAppPurchasesV2` の `NON_CONSUMABLE` /
Play: `inappproducts` の管理対象アイテム）。dev / prod の分けは無い（とん速は flavor を持たない）。

### ストアに登録する商品

**定義の出どころは `iap_products.yaml` の 1 か所だけ。手でストアに登録しない**（ずれる）。

| 商品 ID（iOS / Android 共通） | 種類 | 価格 | 表示名（ja / en / zh） |
|---|---|---|---|
| `tonsoku.non_consumable.remove_ads` | 非消耗型（iOS: Non-Consumable / Play: アプリ内アイテム（管理対象）） | 550 円（税込） | 広告を非表示にする / Remove ads / 移除广告 |

- **商品 ID は登録した後に変えられない・消せない・使い回せない**（両ストア）。叩く前に yaml を確かめる
- ASC の参照名は `Remove Ads`（ASC の中で見分けるだけで、ストアには出ない）
- **ファミリー共有は切ってある**（一度入れると戻せない。入れるならユーザーが決めて Web UI で）

### lane でやること（Claude が叩く。dry-run の結果をユーザーに見せてから apply）

```bash
cd ios     && mise exec -- bundle exec fastlane ios register_iap              # dry-run（既定）
cd ios     && mise exec -- bundle exec fastlane ios register_iap apply:true   # 実登録（不可逆）
cd android && mise exec -- bundle exec fastlane android register_iap              # dry-run（既定）
cd android && mise exec -- bundle exec fastlane android register_iap apply:true   # 実登録（不可逆）
```

- **まず dry-run で、何を作るかを見てから apply する**（three と同じ 2 段）
- **途中で落ちても同じコマンドで続きから直る。** iOS は既にある商品を作り直さず、足りない表示名・
  販売地域だけ補う。Android は既にある商品を飛ばす
- **登録する前に字数を確かめる**（`fastlane/shared.rb` の `iap_non_consumables`）。商品を作った後に
  表示名で弾かれると、商品 ID だけ消費された不完全な商品が残る（three の iOS で踏んだ）
- iOS の販売地域は**全地域**にする（アプリが出ていない地域では商品も買えないので、商品の側で絞る
  意味が無い）。three が JPN だけにしているのは、あちらのアプリの販売地域が日本だけだから
- Android は**無効のまま**作り、価格は日本円を基準に他の国を Play に換算させる

### Web UI でやること（ユーザー）

**iOS（App Store Connect）**

1. **有料 App 契約**（ビジネス → 契約・銀行口座・税務）。**済んでいないと、商品を作れても
   アプリから 1 件も取れない。** 結べるのは Account Holder だけ
2. `register_iap` を apply した後、**価格を付ける**: アプリ内課金 → `Remove Ads` → 価格 →
   基準の国を日本にして ¥550。**lane では付けない** —— three はサブスクの価格を API で日本だけに
   付け、他の地域の価格が作られずに `MISSING_METADATA` から抜けなくなった（ASC の画面にも
   足りない所が出ない。three の setup-app.md「IAP サブスクの価格は ASC Web UI で手動設定」）。
   Web UI の価格の設定だけが全地域の等価の価格を作る。買い切りの価格の API は基準の国から他を
   作る作りだが、**このアカウントで確かめておらず、抜けられない状態に落ちると商品 ID ごと
   使えなくなる**ので、1 回きりの手作業を採る
3. **審査用のスクリーンショット**（購入の画面 = メニューの「広告を非表示にする」の行）を付ける。
   無いと審査に出せない
4. **最初の審査は、アプリの版と一緒に出す**（初めてのアプリ内課金は版の審査に添える決まり）。
   `ios release` の lane は版しか審査に載せない（`precheck_include_in_app_purchases: false`。
   three の release.md の注記と同じ）ので、**審査に出す時に Web UI で商品を審査に加える**
   （`docs/release.md` の「提出前の確認」）

**Android（Play Console）**

1. **お支払いプロファイル（マーチャント アカウント）の連携**（設定 → お支払いプロファイル。
   アカウントの管理者だけ）。無いと lane の apply が
   `Cannot create ... without first registering a payments profile` で落ちる（three の
   troubleshooting ⑥ と同じ）
2. **課金の入ったビルドを 1 度上げておく**（`android alpha draft:true` で足りる）。Play は
   `com.android.vending.BILLING` 権限を持つ版が上がるまで、アプリ内アイテムを作らせない
   （権限は in_app_purchase の Billing ライブラリがマニフェストに足す）
3. `register_iap` を apply した後、**有効にする**（収益化 → 商品 → アプリ内アイテム →
   `tonsoku.non_consumable.remove_ads` → 有効化）。**無効のままだとアプリから商品が取れず、
   テストでも買えない**（three の 1.2.0 の実測。審査とは関係ない）。販売開始なので lane に入れていない
4. **ライセンステスター**を登録する（設定 → ライセンス テスト）。テスターは実際には請求されない

### 試し方

- **iOS: TestFlight から入れる**（TestFlight のアプリの購入は Apple ID に関係なくサンドボックスで、
  請求されない）。**StoreKit の設定ファイル（`.storekit`）は置かない**（three の判断と同じ。商品 ID と
  価格を ASC と二重に持つことになり、ずれた時に商品が取れなくなる）。TestFlight・サンドボックスでは
  価格が USD で出ることがある（Apple 側の既知の挙動。本番では出ない。three の実測）
- **Android: ライセンステスターの端末に、クローズドテストの版をストアから入れる**
  （手元でビルドした版では買えない）
- 確かめること: 買う → 広告（下のバナー・記事の枠）がその場で消え、マップの店舗限定が開く／
  アプリを消して入れ直す → 「購入を復元」で戻る／キャンセル・保留（Android のコンビニ払い）

### 申告

- **App Privacy / データ セーフティの「購入」は「収集しない」のまま**。購入の記録は端末とストアの
  間だけで、こちらのサーバーへは送らない（サーバーを持たない）
- Play のストアの掲載には、商品を有効にすると「アプリ内購入あり」が自動で付く

---

## AdMob

**アプリの登録と広告ユニットの作成はユーザーの手で**（AdMob のコンソール）。作った ID の
差し替え先は README の「広告」（アプリ ID 2 つ・ユニット ID 6 つ。入れてある）。

- iOS / Android それぞれにアプリを登録する（ストアに出る前は「未公開」で登録できる。
  公開後にストアと紐づける）
- **広告ユニットは枠ごとに分ける**（Issue #5。どの位置が稼いでいるかを分けて見るため）
- **手元・テストで本番の ID を使わない**（無効なインプレッションになる。CLAUDE.md の「広告」）
- web の `app-ads.txt` に AdMob の発行者 ID を載せる（web の作業。AdMob が求める）

---

## 環境

- Ruby は `.tool-versions`（3.4.7）。`mise exec --` を頭に付けて叩く
- `mise exec -- bundle install`。`vendor/bundle` に入る（`.bundle/config`）。
  **`Gemfile.lock` は gyumesy と同じ版に揃えてある**（fastlane 2.238.0）
- **`LANG` / `LC_ALL` を UTF-8 にする。** そうしないと fastlane が
  「requires your locale to be set to UTF-8」と警告し、**日本語のエラーが
  文字化けして原因が読めない**（`fastlane/shared.rb` が自分でも直している）

## 他のアプリから持ってくる時の注意

**ストアアカウントが違えば、値は 1 つも流用できない。**
`three-frontend-flutter` は職場のアカウントで、Team ID も Apple ID も鍵の置き場も
別物。**lane の構成だけを参考にして、値は必ず全部書き換える。** 1 つ残ると
別アカウントを向く。

とん速は gyumesy・牛めしレーダーと**同じ運営者のアカウント**なので、Team ID
（`29LP73942P`）・ASC API キー・Play のサービスアカウントは同じものを使う
（`docs/secrets.md`）。**アプリ固有なのは Bundle ID と Android の署名鍵だけ。**
