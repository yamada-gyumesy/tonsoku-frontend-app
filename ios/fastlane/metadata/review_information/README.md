# 審査提出時に添える情報

`deliver`（`fastlane ios release` / `ios metadata`）がここを読んで App Store Connect の
「App レビューに関する情報」へ入れる（gyumesy-frontend-app と同じ置き方）。

**ASC 側で直さない。** 画面で直すと次の `deliver` で黙って上書きされ、
「なぜ通ったのか / なぜ落ちたのか」がリポジトリから追えなくなる。

## 連絡先（氏名・電話・メール）を置いていない理由

**個人の連絡先なので git に入れない**（`docs/setup-app.md` の「審査連絡先」）。
ASC の画面で 1 回だけ入れ、ASC 側に置いたままにする。**ファイルが無い項目は
`deliver` が送らない**ので、画面で入れた値は上書きされない。

## `demo_user.txt` / `demo_password.txt` を置いていない理由

**このアプリはサインインが要らない**ので、デモアカウントの申告は不要
（`appStoreReviewDetail.demoAccountRequired = false`）。

**本当の落とし穴は、片方だけ置くこと**（gyumesy が `deliver` のコードで確かめた）。
`deliver` は**両方が非空の時しか `demo_account_required` を立てない**ので、将来
サインインが要る機能を入れて片方だけ書くと、**「デモアカウント不要」と申告したまま
アカウントが要るアプリを出す**ことになり、審査で確実に止まる。**入れる時は必ず 2 つ揃える。**

## `notes.txt` に必ず残すこと

審査で毎回同じ質問が来る点を先回りして書く（gyumesy の 1.0 で聞かれたもの＋とん速で
増えたもの）:

- **非公式アプリであること**（松のや・松屋フーズホールディングスとの関係が無いこと）。
  ガイドライン 5.2.1 で必ず見られる。ストア掲載文と web の「とん速とは」にも断りを置いてある
- **アカウント不要**であること（デモアカウントを求められないように）
- **位置情報はマップを初めて開いた時（と「現在地」を押した時）に求め、断っても他は使える**こと
  （とん速で増えた。`Info.plist` の `NSLocationWhenInUseUsageDescription` と同じ説明）
- **広告（AdMob）が出る**こと（とん速で増えた。`rating_config.json` の `advertising` と対）
- **外部リンクは `SFSafariViewController`** で開くこと。アドレスバー付きの
  汎用ブラウザは積んでいない（年齢レーティングの `unrestrictedWebAccess = false` の根拠）
- **商品画像が第三者のもの**であること。`submission_information` の
  `content_rights_contains_third_party_content: true` と対で説明が要る
- **掲載は日本語だけだが、アプリ自体は 3 言語で動く**こと。掲載言語とアプリの対応言語が
  食い違っていると、掲載を絞り忘れたのか意図的なのかが審査側から分からない

**出すバイナリと食い違わせないこと。** 広告・位置情報・通知の許可の求め方を変えたら、
ここも直す（提出前に `docs/release.md` の確認項目で見る）。
