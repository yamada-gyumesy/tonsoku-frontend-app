/// 出典 URL から表示用のラベルを作る。
///
/// web の `getThumbnailSourceLabel()` と同じ規則で、**`www.` などのサブドメインを
/// 落とした登録ドメイン**を返す（`www.matsuyafoods.co.jp` → `matsuyafoods.co.jp`）。
/// ホスト名をそのまま出すと web と食い違う（本番の出典 811 件のうち 473 件、58%）。
///
/// `co.jp` / `or.jp` / `ne.jp` / `ac.jp` / `go.jp` は 2 階層で 1 つの接尾辞なので、
/// 3 ラベルぶん残す。それ以外は 2 ラベル。
String? sourceLabelOf(String url) {
  if (url.isEmpty) return null;
  final host = Uri.tryParse(url)?.host;
  if (host == null || host.isEmpty) return null;

  final parts = host.split('.');
  if (parts.length < 2) return host;

  const jpSecondLevel = {'co', 'or', 'ne', 'ac', 'go'};
  final secondLast = parts[parts.length - 2];
  if (jpSecondLevel.contains(secondLast) && parts.length >= 3) {
    return parts.sublist(parts.length - 3).join('.');
  }
  return parts.sublist(parts.length - 2).join('.');
}
