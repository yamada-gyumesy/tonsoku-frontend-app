/// カテゴリ別の通知購読の状態。web の `topics`（`Record<string, boolean>`）。
///
/// **トピック名は web と同じ `tonsoku.category.{id}`** にする
/// （`FirebaseMessagingService.topicFor`）。配信側は 1 系統のままで、既存の配信が
/// そのままアプリにも届く。
///
/// gyumesy-frontend-app の `TopicSelection` を写した。
class TopicSelection {
  const TopicSelection(this._values);

  const TopicSelection.empty() : this(const {});

  final Map<String, bool> _values;

  Map<String, bool> get values => Map.unmodifiable(_values);

  /// **無いキーは「オフ」。**
  ///
  /// 配信にカテゴリが増えた時、保存にはそのキーが無い。**勝手に購読しない**
  /// ——増えるたびに黙って通知が増えると、切った覚えのない人が驚く。
  bool isOn(String categoryId) => _values[categoryId] ?? false;

  TopicSelection toggled(String categoryId, {required bool on}) =>
      TopicSelection({..._values, categoryId: on});

  /// 全部オンで作る。
  ///
  /// **「通知を受け取る」を入れた直後の既定。** web はここで全部オフを焼くが、
  /// 入れた人は通知が欲しいので、そこからさらに 1 つずつ選ばせない
  /// （要らないものだけ後で切ればよい）。
  factory TopicSelection.allOn(Iterable<String> categoryIds) =>
      TopicSelection({for (final id in categoryIds) id: true});

  @override
  bool operator ==(Object other) =>
      other is TopicSelection &&
      other._values.length == _values.length &&
      other._values.entries.every((e) => _values[e.key] == e.value);

  /// **並び順に依らせない。** `==` はキーと値しか見ないので、`hashAll`
  /// （順序つき）だと等しいのにハッシュが違う組が作れる。保存から読んだもの
  /// （JSON の並び）と [allOn]（カテゴリ一覧の並び）は、中身が同じでも並びが
  /// 違いうる。
  @override
  int get hashCode => Object.hashAllUnordered([
    for (final e in _values.entries) Object.hash(e.key, e.value),
  ]);
}
