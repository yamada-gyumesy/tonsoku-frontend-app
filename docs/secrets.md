# 機密ファイルの扱い

**git に入れられず、失うと作り直せないもの**を Google Drive で同期する
（gyumesy-frontend-app の `docs/secrets.md` / `scripts/sync-secrets.sh` と同じ仕組み）。

```bash
bash scripts/sync-secrets.sh download   # 新しい環境で最初にやる
bash scripts/sync-secrets.sh upload     # 鍵を足した / 変えたら
bash scripts/sync-secrets.sh status     # 中身を出さずに両方の一覧を見る
```

## 置き場所

| | |
|---|---|
| Drive（共用） | **`gdrive:gyumesy-secrets/config-gyumesy/`** —— ASC キー・Play 鍵・APNs キー |
| Drive（このリポジトリ） | **`gdrive:gyumesy-secrets/repo/tonsoku-frontend-app/`** —— Android の署名鍵 |
| ローカル（鍵の本体） | **`~/.config/gyumesy/`**（700 / ファイルは 600） |
| ローカル（ビルドが相対パスで読むもの） | リポジトリ内・**すべて `.gitignore` 済み** |

### `~/.config/tonsoku/` を作らない理由

**アカウントの鍵はアカウントに 1 つで、アプリごとに作らない。** とん速は
gyumesy・牛めしレーダーと**同じ運営者の Apple / Google Play アカウント**で出す
（Team ID `29LP73942P`。Bundle ID が `com.gyumesy.*` なのも同じ理由）。

- **ASC API キー**はアカウント（チーム）単位で、どのアプリにも効く
- **Play のサービスアカウント**もデベロッパー アカウント単位。アプリごとの権限を
  Play Console で付けるだけ（`docs/setup-app.md`）
- **APNs キー**もチーム単位で、とん速の Firebase には登録済み

**同じ鍵を 2 か所に置くと、失効・再発行の時に片方だけ古くなる。** 既に
`~/.config/gyumesy/` に揃っているので、そこを指す（`ios/fastlane/Fastfile` の
`ASC_KEY_PATH`、`android/fastlane/Appfile` の `json_key_file`）。

**アプリ固有なのは Android の署名鍵だけ**で、これはリポジトリ内（`.gitignore` 済み）に
置き、Drive では `repo/tonsoku-frontend-app/` に分ける（下の「名前空間」）。

## 何を入れるか

**再取得できないものだけ。** 再生成できるものまで置くと「どちらが正か」が二重になる。

| ファイル | 失うとどうなるか |
|---|---|
| `~/.config/gyumesy/AuthKey_7R3Q2CGK67.p8` | **APNs 認証キー**（共用）。Apple は 1 回しか DL させない |
| `~/.config/gyumesy/AuthKey_BHL97SX4FW.p8` | **ASC API キー**（共用）。同上 |
| `~/.config/gyumesy/appstore-api-key.json` | ASC API キーの Key ID / Issuer ID |
| `~/.config/gyumesy/play-console.json` | Play の Service Account 鍵（共用） |
| `android/keystore/upload.jks` | **とん速の Android 署名鍵。再作成できない。** 失うと Play でアプリを更新できなくなる |
| `android/key.properties` | keystore のパスワード。keystore とセットで意味を持つ |

**入れないもの:**

- **`GoogleService-Info.plist` / `google-services.json`** —— **git にコミットする**
  （README の「プッシュ通知」）。秘密ではなく、アプリバンドルに同梱される前提のもの。
  **秘密でないものを秘密の保管庫に入れると「あそこにあるものは全部秘密」という前提が
  崩れて、本当に危ないもの（`.p8` / keystore）の扱いが緩む**（gyumesy と同じ判断）。
  作り直す時は tonsoku-infra-terraform の `terraform output` から
- **証明書 / プロビジョニングプロファイル** —— Xcode の自動署名に任せる
  （`ios/ExportOptions.plist` の `signingStyle: automatic`）

## Key ID（秘密ではない）

`.p8` の中身が無ければ使えない識別子。

| | 値 | 出どころ |
|---|---|---|
| **Apple Team ID** | **`29LP73942P`** | Firebase の iOS アプリ登録・`project.pbxproj` の `DEVELOPMENT_TEAM` |
| Apple ID | `gyumesy@icloud.com` | `gyumeshi-rader-app/fastlane/Appfile` |
| APNs Key ID | `7R3Q2CGK67` | `.p8` のファイル名 |
| ASC API Key ID | `BHL97SX4FW` | `ios/fastlane/Fastfile` |

**`three` の Team ID（別会社）と混ぜないこと。** three の Fastfile をコピーして
Team ID や鍵のパスを残すと、**別会社のストアを向く**。

## リポジトリごとに名前空間を分けている

**分けないと `android/key.properties` が他のアプリのものと衝突する。**
どれも `repo/android/key.properties` へ送ると奪い合いになり、**上書きされた側は
「Drive にバックアップがある」と思ったまま鍵のパスワードを失い、気付くのは Play へ
アップロードする時**になる（gyumesy が分けた理由）。とん速は `repo/tonsoku-frontend-app/`。

`config-gyumesy/` は共用のまま（同じ実体を複数のアプリで使っている）。

## `sync` ではなく `copy` を使っている

**`rclone sync` はリモート側の余計なファイルを消す。** `~/.config/gyumesy/` は共用で
**環境によって持つファイルが違う**ので、片方から `sync` すればもう片方しか持たない鍵が
消える。**再取得できないものを扱う以上、古いファイルが残るほうが安全**なので `copy` にして
いる。**自動で消す経路は作らない。**

## 事故を防いでいるもの

`sync-secrets.sh` は **`git check-ignore` を実際に呼んで**、リポジトリ内へ降ろすファイルが
無視対象であることを確かめてから動く。目視の約束にすると、いつか漏れる
（ディレクトリのパターンは末尾スラッシュが要る。スクリプトのコメント）。

**`download` は「降ろせなかった」を必ず出す。** とん速の名前空間は**最初の `upload` まで
空**なので、署名鍵を作る前に新しい環境を作ると `~/.config/gyumesy/` だけ降りる。
それは正常（まだ鍵が無い）だが、鍵を作った後なら `upload` し忘れている。

`status` は**名前と大きさしか出さない**。中身を画面に出す経路をこの仕組みに作らない。
