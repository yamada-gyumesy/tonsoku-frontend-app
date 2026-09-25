# iOS / Android の両 Fastfile が使う補助。
#
# **gyumesy-frontend-app の同名ファイルをそのまま写した**（アプリ固有の値を
# 持たないので書き換える所が無い）。コメントの「1.0 で踏んだ」は gyumesy の
# 実測で、とん速ではまだ踏んでいない —— 同じ fastlane を使う以上、同じ所で落ちる。
#
# **2 つに書き写さない。** 片方だけ直すと、次に配信した時にどちらの規律が
# 効いているのか分からなくなる。
#
# **`UI` ではなく `FastlaneCore::UI` と書くこと。** ここは `Fastfile` の中では
# なく素の Ruby として読まれるので、`UI` という定数は解決できない
# （`uninitialized constant UI` になり、**見張りが止めたいものとは別の理由で
# 落ちる**——メッセージが出ないので原因が分からない）。`sh` はメソッドなので
# 呼び出し時に解決され、そのまま使える。

# **fastlane は UTF-8 のロケールを要求する。**
#
# シェルの `LANG` が空（`LC_CTYPE=C`）だと Ruby の既定の外部エンコーディングが
# US-ASCII になり、**日本語を含む掲載情報を読んだ瞬間に落ちる**
# （`deliver/upload_metadata.rb` の `String#strip` で
# `invalid byte sequence in US-ASCII`）。**1.0 の再提出がここで落ちた** ——
# しかも `deliver` は掲載情報の前に審査を取り下げるので、**取り下げただけで
# 止まった状態**になり、審査に出ていないことに気づきにくい。
# `git tag` が打てなかったのも同じ原因。
#
# **`ENV` を書くだけでは直らない。** `Encoding.default_external` は Ruby の
# 起動時にロケールから決まるので、後から環境変数を変えても効かない。
# **両方やる** —— `Encoding` は自分のため、`ENV` は `sh` で呼ぶ子プロセスのため。
Encoding.default_external = Encoding::UTF_8 if Encoding.default_external != Encoding::UTF_8
%w[LANG LC_ALL].each do |key|
  ENV[key] = "en_US.UTF-8" unless ENV[key].to_s.match?(/UTF-?8/i)
end

REPO_ROOT = File.expand_path("..", __dir__)

# versionCode / build number は epoch 秒。
#
# **int32（最大 2,147,483,647）に収まるのは 2038-01-19 まで**だが、
# Play の versionCode の上限は **2,100,000,000** なので、実際に頭を打つのは
# **2036-07-18**。
def build_number
  Time.now.to_i
end

def flutter_semver
  line = File.readlines(File.join(REPO_ROOT, "pubspec.yaml")).find { |l| l =~ /^version:\s*\S/ }
  FastlaneCore::UI.user_error!("pubspec.yaml に version: が無い") unless line
  line.sub(/^version:\s*/, "").strip.split("+").first
end

# **出荷したものを記録する不変のタグ。** 何を出したかの正であり、リリース
# ブランチが消えた時の復元アンカーでもある。**絶対に消さない。**
def tag_build(os:, build_number:)
  version = flutter_semver
  tag = "#{os}-#{version}-b#{build_number}"
  Dir.chdir(REPO_ROOT) do
    commit = sh("git", "rev-parse", "HEAD").strip
    sh("git", "tag", "-a", tag, commit, "-m", "#{os} #{version} build #{build_number}")
    sh("git", "push", "origin", tag)
  end
  FastlaneCore::UI.success("build タグ #{tag} を打ちました")
rescue => e
  # **配信は成功しているので止めない。** ただし案内は失敗した段階で変わる ——
  # タグを作れていれば残りは push だけで、`git tag -a` を叩くと
  # `already exists` で止まる
  exists = Dir.chdir(REPO_ROOT) { system("git", "rev-parse", "-q", "--verify", "refs/tags/#{tag}", out: File::NULL) }
  FastlaneCore::UI.error("build タグ #{tag} を打てませんでした（#{e.message}）。**配信は成功しています。**")
  FastlaneCore::UI.error(
    if exists
      "タグはローカルにあります。残りは push だけ: git push origin #{tag}"
    else
      "手で: git tag -a #{tag} <出荷コミット> && git push origin #{tag}"
    end,
  )
end

# **配信するブランチを間違えない。** 手元で叩いた時に checkout しているものが
# そのまま出荷される。`main` には次のリリースの先行機能が乗るので、それを審査に
# 出す事故を止める。
#
# **審査へ出す lane にも付ける**（`ios release` / `android promote`）。
# 出荷の瞬間はそこなので、ビルドする lane だけ見張っても意味がない。
def ensure_release_branch
  branch = Dir.chdir(REPO_ROOT) { sh("git", "rev-parse", "--abbrev-ref", "HEAD").strip }
  if branch == "HEAD"
    FastlaneCore::UI.user_error!("detached HEAD です。`release-<version>` を checkout してください。")
  end
  return if branch.start_with?("release-")

  FastlaneCore::UI.user_error!(
    "いま `#{branch}` に居ます。配信は `release-<version>` から行ってください。\n" \
    "`main` には次のリリースの先行機能が乗るので、そのまま出すと未承認の機能を審査に出すことになります。"
  )
end

# **出荷物とタグを一致させる。** ビルドするのは作業ツリー、タグが指すのは
# `HEAD`。コミットし忘れた 1 行を含む成果物を配ると、**タグは出荷物を指さない**。
#
# `.gitignore` 済みの鍵は `--porcelain` に出ないので、鍵があっても止まらない。
def ensure_shippable_tree
  dirty = Dir.chdir(REPO_ROOT) { sh("git", "status", "--porcelain").strip }
  return if dirty.empty?

  FastlaneCore::UI.user_error!(
    "作業ツリーに未コミットの変更があります。**出荷物とタグがずれます。**\n" \
    "コミットしてから配信してください:\n#{dirty}"
  )
end
