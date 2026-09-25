#!/bin/bash
# =============================================================================
# 機密ファイルの Google Drive 同期
#
# **git に入れられないが、失うと作り直せないファイル**を Drive と上下同期する。
# 置き場所は `gdrive:gyumesy-secrets`（rclone のリモート `gdrive:`）。
#
# **gyumesy-frontend-app の同名スクリプトを写した。** 変えたのは `REPO_NAME` だけ。
# **保管庫（`gyumesy-secrets`）と鍵の置き場（`~/.config/gyumesy/`）はそのまま
# 共用する** —— とん速は同じ運営者の Apple / Google Play アカウントで出すので、
# ASC API キー・Play のサービスアカウント・APNs キーは gyumesy と同じ実体
# （`docs/secrets.md` の「置き場所」）。
#
#   bash scripts/sync-secrets.sh upload    # ローカル → Drive
#   bash scripts/sync-secrets.sh download  # Drive → ローカル
#   bash scripts/sync-secrets.sh status    # 両方の一覧を並べる（中身は出さない）
#
# **`gyumesy-backend-batch/scripts/sync-env.sh` と同じ流儀。** あちらが
# `gdrive:gyumesy-batch-env` に `.env` / `credentials/` を同期しているのと同型で、
# rclone の認証（`gdrive:` リモート）もそのまま使う。`three-frontend-flutter` の
# `scripts/sync_secrets.py` は Google OAuth を自前で持つが、ギュメシーには既に
# rclone の流儀があるので**新しい認証系を増やさない**。
#
# -----------------------------------------------------------------------------
# 何を入れて、何を入れないか
# -----------------------------------------------------------------------------
# **入れるのは「再取得できないもの」だけ。** 再生成できるものまで置くと
# 「どちらが正か」が二重になる。
#
#   AuthKey_<KeyID>.p8   APNs 認証キー。**再ダウンロード不可**（Apple は 1 回きり）
#   AuthKey_<KeyID>.p8   ASC API キー。同上（rader-app と共用）
#   appstore-api-key.json / play-console.json   ストアの認証情報
#   *.jks / *.keystore   Android 署名鍵。**再作成できない**。失うと Play で
#                        アプリを更新できなくなる
#   key.properties       keystore のパスワード。keystore とセットで意味を持つ
#
# **入れないもの:**
#
#   GoogleService-Info.plist / google-services.json
#     → git にコミットしてある（秘密ではない。`docs/secrets.md`）。作り手は
#       `tonsoku-infra-terraform`
#   証明書 / プロビジョニングプロファイル
#     → `fastlane match` が別のリポジトリで管理する
# =============================================================================

set -euo pipefail

REMOTE="gdrive:gyumesy-secrets"

# **リポジトリごとに名前空間を分ける。** 分けないと `android/key.properties` が
# `gyumeshi-rader-app` のものと**同じ `repo/android/key.properties` を奪い合う**
# （keystore 本体はパスが違うので無事だが、key.properties だけ衝突する）。
# 上書きされた側は「Drive にバックアップがある」と思ったまま鍵のパスワードを失い、
# **気付くのは Play へアップロードする時**になる。
REPO_NAME="tonsoku-frontend-app"

# **鍵の実体はリポジトリの外に置く。** `~/.config/gyumesy/` は
# `gyumeshi-rader-app` が既に使っている場所で、そちらの `fastlane/Appfile` と
# `Fastfile` が直接この絶対パスを指している。同じ場所に揃えることで、
# 牛めしレーダー・ギュメシー・とん速で同じ ASC キー・Play 鍵を共用できる
CONFIG_DIR="$HOME/.config/gyumesy"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# リポジトリ内に置く必要があるもの（ビルドが相対パスで読むため）。
# **すべて .gitignore 済みであること**を下で確かめる
REPO_FILES=(
  "android/key.properties"
)
REPO_DIRS=(
  "android/keystore"
)

die() { echo "Error: $*" >&2; exit 1; }

command -v rclone >/dev/null || die "rclone が無い。https://rclone.org/install/"
rclone listremotes | grep -qx 'gdrive:' \
  || die "rclone のリモート 'gdrive:' が無い。'rclone config' で作る（backend-batch の README 参照）"

# **git に入りうる場所を同期対象にしていないか、実際に git に聞いて確かめる。**
# ここを目視の約束にすると、いつか漏れる
# **実体が無くても判定できる**（`git check-ignore` はパス文字列で判断する）。
# ただし**ディレクトリのパターンは末尾スラッシュが要る** —— `android/keystore/` は
# ディレクトリ専用のパターンなので、実体が無い状態で末尾スラッシュ無しを渡すと
# 「無視されない」と判定される:
#
#   android/key.properties → 無視される      （実体なし）
#   android/keystore       → 無視されない ★  （実体なし）
#   android/keystore/      → 無視される      （実体なし）
check_ignored() {
  local path="$1"
  git -C "$PROJECT_DIR" check-ignore -q "$path" \
    || die "$path が .gitignore に入っていない。git に入る前に止めた"
}

case "${1:-}" in
  upload)
    for f in "${REPO_FILES[@]}"; do check_ignored "$f"; done
    for d in "${REPO_DIRS[@]}"; do check_ignored "$d/"; done

    mkdir -p "$CONFIG_DIR"
    echo "Uploading to $REMOTE ..."

    if [ -d "$CONFIG_DIR" ] && [ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
      # **`sync` ではなく `copy`。** `sync` はリモート側の余計なファイルを消す。
      # `~/.config/gyumesy/` は他のアプリと共用していて**環境によって持つ
      # ファイルが違う**ので、片方から `sync` するともう片方しか持たない鍵が消える
      # （実際この環境でも作業中に 3 → 4 に変わった）。再取得できないものを扱う
      # 以上、**古いファイルが残るほうが安全**。自動で消す経路は作らない
      rclone copy "$CONFIG_DIR/" "$REMOTE/config-gyumesy/" --progress
      echo "  config-gyumesy/  ($(ls -1 "$CONFIG_DIR" | wc -l | tr -d ' ') files)"
    fi

    for f in "${REPO_FILES[@]}"; do
      [ -f "$PROJECT_DIR/$f" ] || continue
      rclone copy "$PROJECT_DIR/$f" "$REMOTE/repo/$REPO_NAME/$(dirname "$f")/"
      echo "  repo/$REPO_NAME/$f"
    done
    for d in "${REPO_DIRS[@]}"; do
      [ -d "$PROJECT_DIR/$d" ] || continue
      rclone copy "$PROJECT_DIR/$d/" "$REMOTE/repo/$REPO_NAME/$d/"
      echo "  repo/$REPO_NAME/$d/"
    done
    echo "Done."
    ;;

  download)
    mkdir -p "$CONFIG_DIR"
    echo "Downloading from $REMOTE ..."

    # **「降ろせなかった」を黙って通さない。**
    #
    # 名前空間を分けたので**新パスは最初の `upload` まで空**で、その状態で新しい
    # 環境を作ると `~/.config/gyumesy/` だけ降りて署名鍵が静かに落ちる。
    # `Done.` だけ出て、**気付くのは `flutter build appbundle` の時**になる。
    # この手順書が案内している唯一の復旧手順が、半分しか仕事をしていない形。
    missing=0

    # **`set -e` で落とさない。** 裸で書くと、途中で失敗した瞬間に下の `chmod` へ
    # 届かず、**降りたぶんの鍵が 644 のまま残る**（この直後のコメントが言っている
    # 状態がそのまま残る）。しかも非 0 で終わるので、利用者は「失敗した」とだけ
    # 受け取り、中途半端に降りたファイルが残っていることに気付きにくい。
    #
    # **さらに、ここで落ちると下の「Drive に無し」が一度も出ない。**
    # `config-gyumesy/` がまだ空＝**新パスへ移行している最中**がまさにその状態で、
    # いちばん報告が要る場面を通らなくなる。
    rc=0
    rclone copy "$REMOTE/config-gyumesy/" "$CONFIG_DIR/" --progress || rc=$?

    # **鍵は本人だけが読める権限にする。** Drive から降ろした直後は 644 になる。
    # **取得の成否によらず必ず通す**（中途半端に降りたぶんも締める）
    chmod 700 "$CONFIG_DIR"
    find "$CONFIG_DIR" -type f -exec chmod 600 {} +
    if [ "$rc" -eq 0 ]; then
      echo "  $CONFIG_DIR/ (600)"
    else
      # **`${rc}` と区切る。** `$rc）` は全角括弧まで変数名として読まれ、
      # `set -u` が「未割り当て」で落とす（実際に踏んだ）
      echo "  ** 共用ぶんの取得に失敗（rclone 終了コード ${rc}）"
      echo "     降りたぶんの権限は締めた: $CONFIG_DIR/ (600)"
      missing=$((missing + 1))
    fi
    for f in "${REPO_FILES[@]}"; do
      if rclone copy "$REMOTE/repo/$REPO_NAME/$f" \
        "$PROJECT_DIR/$(dirname "$f")/" 2>/dev/null; then
        echo "  $f"
      else
        echo "  ** Drive に無し: repo/$REPO_NAME/$f"
        missing=$((missing + 1))
      fi
    done
    for d in "${REPO_DIRS[@]}"; do
      if rclone copy "$REMOTE/repo/$REPO_NAME/$d/" "$PROJECT_DIR/$d/" 2>/dev/null \
        && [ -n "$(ls -A "$PROJECT_DIR/$d" 2>/dev/null)" ]; then
        echo "  $d/"
      else
        echo "  ** Drive に無し: repo/$REPO_NAME/$d/"
        missing=$((missing + 1))
      fi
    done

    for f in "${REPO_FILES[@]}"; do check_ignored "$f"; done
    for d in "${REPO_DIRS[@]}"; do check_ignored "$d/"; done

    if [ "$missing" -gt 0 ]; then
      echo
      echo "Done（$missing 件が Drive に無い）。"
      echo "  まだ誰も upload していないか、パスが違う。"
      echo "  署名鍵が降りていないと flutter build appbundle まで気付けない。"
    else
      echo "Done."
    fi
    ;;

  status)
    # **中身は出さない。名前と大きさだけ。**
    echo "--- local: $CONFIG_DIR"
    ls -l "$CONFIG_DIR" 2>/dev/null | tail -n +2 | awk '{print "  " $5 "\t" $9}' \
      || echo "  (無し)"
    # **他リポジトリのぶんを混ぜない。** まとめて出すと、自分が上げたものと
    # 他のアプリが上げたものの区別が付かない
    echo "--- remote: $REMOTE/config-gyumesy （共用）"
    rclone lsl "$REMOTE/config-gyumesy" 2>/dev/null | awk '{print "  " $1 "\t" $4}'
    echo "--- remote: $REMOTE/repo/$REPO_NAME"
    rclone lsl "$REMOTE/repo/$REPO_NAME" 2>/dev/null | awk '{print "  " $1 "\t" $4}'
    ;;

  *)
    echo "Usage: bash scripts/sync-secrets.sh [upload|download|status]"
    exit 1
    ;;
esac
