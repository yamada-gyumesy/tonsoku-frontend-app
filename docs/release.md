# リリース手順

**iOS / Android 同時リリース。** ここは**毎リリースやること**だけ。

- **アプリに 1 回だけのもの**（Bundle ID の登録・署名鍵の作成・ストアの申告）は
  `docs/setup-app.md`
- **いま何が済んでいて何が誰待ちか**は `docs/release-state.md`

判定基準は **「次の 1.0.1 でも、また同じことをやるか？」**。
はい → ここ / いいえ → `setup-app.md`。

**gyumesy-frontend-app の `docs/release.md` と同じ手順**（lane も同じものを写した）。
落とし穴の「1.0 で踏んだ」は gyumesy の実測。

## 前提

- `~/.config/gyumesy/` に認証情報が揃っていること（共用。`docs/secrets.md`）
- `android/key.properties` と `android/keystore/upload.jks` があること
  （`bash scripts/sync-secrets.sh download`）
- `mise exec -- bundle install` が通ること（Ruby は `.tool-versions` の 3.4.7）
- **`LANG` / `LC_ALL` が UTF-8 であること。** そうしないと fastlane の日本語の
  エラーが文字化けして、原因が読めない

## ブランチ

**配信は必ず `release-<version>` から行う。** 手元で叩いた時に checkout して
いるブランチがそのまま出荷されるので、`main` から叩くと**次のリリースの先行機能を
審査に出す**ことになる。lane の頭で見張っていて、`release-` で始まらない
ブランチからは止まる（`fastlane/shared.rb` の `ensure_release_branch`）。

- `main` から `release-<version>` を切る
- **`main → release` は禁止**（マージも、release を main から作り直すのも）
- `release → main` は OK（審査提出が済んだらマージ）

## 流れ

1. `release-<version>` を切り、`pubspec.yaml` の `version:` を上げる
   （`+N` の部分は lane が epoch 秒で自動採番するので気にしない）
2. **提出前に掲載情報と実体を突き合わせる**（下の「提出前の確認」）
3. **Android → iOS の順**でテスト配信する（並列に走らせない）

   ```bash
   cd android && mise exec -- bundle exec fastlane android alpha
   cd ios     && mise exec -- bundle exec fastlane ios beta
   ```

   **Play の初回だけ `alpha draft:true`**（未公開のアプリは draft でしか上げられない）

4. 動作を確認したら審査へ

   ```bash
   cd ios     && mise exec -- bundle exec fastlane ios release
   cd android && mise exec -- bundle exec fastlane android promote version_code:<alpha の versionCode>
   ```

   **Android の本番は、クローズドテスト 12 人 × 14 日を満たすまで出せない**
   （Play の個人デベロッパーの要件。gyumesy はまだ満たしていない）。それまでは `alpha` だけ

5. 審査が通って公開されたら、通過したビルドのコミットに `<os>-<version>` を打ち、
   GitHub Release を **OS ごとに 1 本**出す。差分の起点は
   `--notes-start-tag` で前回の同 OS タグを明示する（タグが混在するので自動推測は誤る）

## 提出前の確認

**審査メモ・申告とバイナリを食い違わせない。** どれもビルドも lane も通るので、
審査で聞かれるまで気づけない。

- `ios/fastlane/metadata/review_information/notes.txt` — 広告・位置情報・通知の許可の
  求め方が今のアプリと合っているか
- `ios/fastlane/rating_config.json` の `advertising` — 広告が入っている版なら true
- **App Store の掲載情報に「松のや」を名前・サブタイトル・説明文の 1 行目・プロモーション
  テキストで出していないか**（冒頭に商標の語が来ると Apple に弾かれる。ユーザーの判断。
  説明文の本文とキーワードには入っていてよい。gyumesy が 4.1(a) で落ちたのは見出しと
  サブタイトル）。**Google Play は冒頭に出してよい**（短い説明・説明文の 1 行目も「松のや」の
  ままにしてある。ユーザーの判断）
- 説明文の非公式の断り（「非公認ファンメディア」）が残っているか
- **アプリ内課金の商品を初めて出す版は、Web UI で商品を審査に加える**（ASC → 版のページの
  「アプリ内課金とサブスクリプション」、または審査の提出に商品を足す）。**`ios release` は版しか
  審査に載せない**（`precheck_include_in_app_purchases: false`）。商品は価格と審査用の
  スクリーンショットが揃うまで加えられない（`docs/setup-app.md` の「アプリ内課金の商品」）

## lane

### Android

| lane | 内容 |
|---|---|
| `alpha` | ビルド → **クローズドテスト**（内部テストではない） |
| `promote version_code:NNN` | alpha のビルドを本番へ昇格（再ビルドしない） |
| `metadata` | 掲載情報・スクリーンショットだけ |
| `build` | AAB を作るだけ |

**`promote` は `track` と `track_promote_to` を両方渡している。** `track` と
`version_code` だけだと supply が「AAB 無しのアップロード」と解釈して**黙って
何もしない**（exit 0 のまま）。

**本番への昇格は draft で止まる。** 初回公開前は draft が必須で、公開後も
draft にしておけば審査・公開が手動になり、自動公開の事故が無い。

### iOS

| lane | 内容 |
|---|---|
| `beta` | ビルド → TestFlight |
| `release` | 掲載情報を反映して**審査提出**（出荷の瞬間はここだけ） |
| `metadata` | 掲載情報だけ（`skip_screenshots:false` でスクショも差し替え） |
| `resubmit` | **審査中の**ものを取り下げてビルドを差し替え、再提出 |
| `rejected_rebuild` | **リジェクト後**①: ビルドと掲載情報を差し替える（提出しない。`skip_build:true` / `skip_screenshots:true`） |
| `rejected_submit` | **リジェクト後**②: 却下項目を解決して再提出 |
| `register_app_id` / `create_app` | アプリに 1 回だけ（`docs/setup-app.md`） |
| `build` | ipa を作るだけ |

**`release` はバイナリを上げない。** 上げるのは `beta` で、`release` は掲載情報と
提出だけ。**文言を直すだけなら `metadata` を使う** —— `release` は `deliver` の
`submit_for_review` が既定 true で `force: true` も付くので、直すたびに提出まで走る。

**`metadata skip_screenshots:false` の後は ASC で枚数を数えること。** `deliver` は
処理待ちの再試行で同じ画像を二重に上げることがある。`overwrite_screenshots` を
付けていても防げない（詳細は Fastfile のコメント）。**gyumesy の 1.0 では 2 回とも
4 枚が 8 枚になった。** `rejected_rebuild` は送った直後に数えて畳む
（`verify_app_screenshots!`）が、`metadata` は数えないので目で数える。

### リジェクトされた後の再審査

**`release` では出せない。** `deliver` は **`UNRESOLVED_ISSUES` の submission を
「審査中」とみなす**ので、リジェクトされた submission が残っている限り
`Cannot submit for review - A review submission is already in progress` で止まる。

**`resubmit` は使わない。落ちずに壊す。** あちらは `reject_if_possible: true` を
渡していて、`deliver` は掲載情報を送る前に `cancel_submission` を実行する。
**通れば submission が作り直されて Apple への返信が別スレッドに分かれ**、
通らなければ**タイムアウトの無いループで永久に待つ**。

**返信は提出の前。** Apple が返信を受け付けるのは
[`until you resubmit to App Review`](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/reply-to-app-review-messages/)
まで。**API では投稿できない**ので、そこだけ手で貼る。だから lane が 2 つに
割れている。

```sh
cd ios && mise exec -- bundle exec fastlane ios rejected_rebuild
# ASC → 該当バージョン → App Review に返信を貼る（手作業）
cd ios && mise exec -- bundle exec fastlane ios rejected_submit
```

**掲載情報の指摘なら同じビルドでも出し直せる。** `skip_build:true` は
**いま版に付いているビルドをそのまま使う**（TestFlight の最新を拾わない）。

**`whatsNew` は 1.0 では入らない。** ASC が初回リリースに「新機能」欄を持たないため、
`metadata/*/release_notes.txt` は置いてあっても無視される（次の更新から効く）。

**`content_rights_contains_third_party_content` を true にしている。** 記事は
自前だが**松のやの商品画像を引用している**ため。

## タグ

配信のたびに `<os>-<version>-b<buildNumber>` を打って push する（lane が自動）。
**何を出したかの正**であり、リリースブランチが消えた時の復元アンカーでもある。
**絶対に消さない**（消すと出荷コミットが GC される）。

## 落とし穴

- **シェルのロケールを UTF-8 にしてから叩く。** `LANG` が `C` / `US-ASCII` だと
  `deliver` が日本語の掲載情報を読んだ瞬間に `invalid byte sequence in US-ASCII` で
  落ちる。cron や CI から叩く時は明示すること:

  ```bash
  LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8 mise exec -- bundle exec fastlane ios metadata
  ```
- **ビルドは必ず clean してから。** 差分ビルドだとソースの変更が成果物に入らない
  まま versionCode だけ上がることがある（lane が `flutter clean` を入れている）
- **iOS のビルドは `Bundler.with_unbundled_env` で包む。** `flutter build` は中で
  CocoaPods（Homebrew の ruby）を呼ぶので、bundler の環境変数が漏れると pod が壊れる
- **ipa の名前を決め打ちしない。** Xcode の product 名から決まるので
  `pubspec.yaml` の `name` と一致するとは限らない（lane は出来たものを拾う）
