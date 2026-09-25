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

**lane を叩くのは、認証情報を持っている人（ユーザー）だけ。** 認証情報の置き場は
`docs/secrets.md`。

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
（Firebase の iOS アプリ登録に入れる。`docs/release-state.md` の「待ち」）。

### 審査連絡先（`appStoreReviewDetail`）

**これが無いと `fastlane ios metadata` が `No data` で落ちる。** `deliver` は
掲載情報を入れるだけの時でも必ず `fetch_app_store_review_detail` を通るので、
審査に出す前から必要になる（`deliver/upload_metadata.rb:752`）。

作られるのは**版ごとではなくアプリの最初の版に 1 回**。ASC の
「App Review Information」を UI で埋める。

- `contactFirstName` / `contactLastName` / `contactPhone` / `contactEmail` は**個人の連絡先**。
  **リポジトリに置かない**。ASC 側に置いたままにする（ファイルが無い項目は `deliver` が送らない）
- `demoAccountRequired` は `false`（ログインが無いアプリなので）
- `notes` は `ios/fastlane/metadata/review_information/notes.txt` が持つ（`deliver` が送る）

### App Privacy（データ収集の申告）

**ASC の UI のみ。** とん速は gyumesy と違って**広告（AdMob）**と**位置情報**を持つので、
gyumesy の申告を写さない。**広告の実装（Issue #5）が入ってから、その SDK が集めるものに
合わせて答える**（AdMob の「データの種類」の開示に従う。ATT を出すなら「トラッキング」も）。

- 位置情報: マップの「現在地」で使うが**端末の外へ送らない**（地図を寄せるだけ）
- 通知: FCM のトークン（デバイス ID 相当）
- 計測: GA4 はまだ入っていない（入れた時に足す）

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

**本当に無い時だけ**作る（**ユーザーの手で**。パスワードを決めるのも保管するのも本人）:

```bash
keytool -genkeypair -keystore android/keystore/upload.jks -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload \
  -dname "CN=..., C=JP"
# パスワードは対話で入れる（コマンド行に書くとシェルの履歴に残る）
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
署名し直される。** そちらの指紋は Play Console でアプリを作った後に
「アプリの完全性」に出る。**`assetlinks.json` には両方要る**（ストアから入れた端末は
アプリ署名鍵、手元で入れた端末はアップロード鍵で署名されている）。

### Play のアプリ

**UI のみ。** `package name`（`com.gyumesy.tonsoku`）は**初回確定で変更不可**。

作った後、**Play Console の「ユーザーと権限」でサービスアカウントに
このアプリへのアクセスを付ける**こと。付いていないと `supply` が
`Invalid request` で弾かれ、**「アプリが無い」のか「権限が無い」のか
API からは区別できない**。

UI でしか入れられない申告（gyumesy と違うところだけ）:

- **広告: 「含まれている」**（AdMob）。**`AD_ID` 権限を消さない**（gyumesy は広告を持たないので
  消しているが、AdMob は広告 ID を使う。消すと広告の配信が制限される）
- データ セーフティ: 位置情報（端末内のみ）・デバイス ID（FCM）・広告 SDK が集めるもの
- 対象年齢・コンテンツレーティング（IARC）

---

## AdMob

**アプリの登録と広告ユニットの作成はユーザーの手で**（AdMob のコンソール）。作った ID の
差し替え先は `docs/release-state.md` の 8（アプリ ID 2 つ・ユニット ID 6 つ）と README の「広告」。

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
