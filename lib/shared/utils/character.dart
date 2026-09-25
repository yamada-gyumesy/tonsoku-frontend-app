/// のや子（編集後記の話し手）の絵。web の `models/expression.ts` / `utils/cdn.ts`。
///
/// **`characters/` の下をキャラで割ってある**（`noyako` は開発側の通称で、パスに
/// だけ使う。画面には出さない）。
///
/// **`AppConfig.cdnBaseUrl` を使わず、本番の CDN を直に指す**（web と同じ判断）。
/// 手元の mock CDN にはこの絵が入らない（web の `sync-cdn` はブランドのアセットを
/// 写さない）。内容も URL も変わらない絵なので、手元でも本番と同じものが出るほうが
/// 確かめやすい。
const _characterBase = 'https://cdn.ton-soku.com/characters/noyako';

/// 表情。**値はバックエンドが決める**（記事の `expression`）。
///
/// **知らない値は `normal` に倒す。** 絵が 4 枚しか無いので、値が増えた時に
/// 出すものが無い。落とすより既定の顔を出すほうが害が少ない（バックエンドも
/// そう決めている）。
const _expressions = {'normal', 'smile', 'angry', 'confused'};

String expressionUrl(String? expression) {
  final resolved = _expressions.contains(expression) ? expression! : 'normal';
  return '$_characterBase/$resolved.svg';
}
