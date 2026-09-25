/// 注文方法（チャネル）の扱い。web の `coupon.ts` の `CHANNEL_DISPLAY` /
/// `CHANNEL_RATE_KEYS`。
library;

/// 表示上の注文方法。**松弁デリバリーは松弁ネットに畳む。**
///
/// 同じ松弁の入口で付与率も条件も同じなので、行を分けても読者の判断は変わらず、
/// **同じ数字の行が 2 つ並ぶだけ**になる。
const _channelDisplay = <String, String>{
  'matsuben_net': 'matsuben_net',
  'matsuben_delivery': 'matsuben_net',
  'mobile_order': 'mobile_order',
  'store': 'store',
};

/// **配信側の `ranks[].rates` のキーとチャネルの対応はここだけに書く。**
/// 増やす時はここを直せば、倍率の幅の計算も表示も一緒に追随する。
///
/// **店舗払いは `rates` に系統が無い**ので率を出せない（その時は幅も注記も出さない）。
const _channelRateKeys = <String, String?>{
  'matsuben_net': 'matsuben',
  'matsuben_delivery': 'matsuben',
  'mobile_order': 'mobile_order',
  'store': null,
};

String displayChannel(String id) => _channelDisplay[id] ?? id;

/// 畳んだうえで重複を除いた注文方法。**配信は松弁ネットとデリバリーを別々に持つ。**
///
/// 順序は配信の順を保つ（`Set` に入れて戻すだけだと Dart では挿入順が保たれるが、
/// **意図として保っている**ことを明示するために `LinkedHashSet` の既定に頼らず書く）。
List<String> displayChannels(List<String> ids) {
  final out = <String>[];
  for (final id in ids) {
    final d = displayChannel(id);
    if (!out.contains(d)) out.add(d);
  }
  return out;
}

/// その注文方法に効く松屋ポイントの付与率の系統。倍率クーポンの率の幅を出すのに要る。
String? rateKeyOf(String id) => _channelRateKeys[id];
