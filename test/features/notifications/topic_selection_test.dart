import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/features/notifications/domain/topic_selection.dart';

/// カテゴリ別の通知購読。
///
/// **保存ボタンは無い**（触った時点で反映する）ので、web にあった「変更あり」
/// の判定はここに無い。残っているのは値の持ち方だけ。
void main() {
  const categories = ['menu', 'campaign', 'store'];

  /// **配信にカテゴリが増えた時に勝手に購読しない。** 増えるたびに黙って通知が
  /// 増えると、切った覚えのない人が驚く
  test('無いキーはオフ', () {
    const s = TopicSelection({'menu': true});
    expect(s.isOn('menu'), isTrue);
    expect(s.isOn('store'), isFalse);
  });

  /// **「通知を受け取る」を入れた直後の既定。** 入れた人は通知が欲しいので、
  /// そこからさらに 1 つずつ選ばせない
  test('全部オンで作れる', () {
    final s = TopicSelection.allOn(categories);
    for (final id in categories) {
      expect(s.isOn(id), isTrue, reason: id);
    }
    expect(s.values.keys, containsAll(categories));
  });

  test('切り替えても他は変わらない', () {
    final s = TopicSelection.allOn(categories).toggled('menu', on: false);

    expect(s.isOn('menu'), isFalse);
    expect(s.isOn('campaign'), isTrue);
    expect(s.isOn('store'), isTrue);
  });

  /// **`==` が真ならハッシュも一致すること。** 保存から読んだもの（JSON の
  /// 並び）と [TopicSelection.allOn]（カテゴリ一覧の並び）は、中身が同じでも
  /// 並びが違いうる。順序つきのハッシュだと `Set` に 2 個入る
  test('並びが違っても、中身が同じならハッシュも同じ', () {
    const a = TopicSelection({'menu': true, 'campaign': false});
    const b = TopicSelection({'campaign': false, 'menu': true});

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect({a, b}, hasLength(1));
  });

  test('同じ中身なら等しい', () {
    expect(
      const TopicSelection({'menu': true}),
      const TopicSelection({'menu': true}),
    );
    expect(
      const TopicSelection({'menu': true}),
      isNot(const TopicSelection({'menu': false})),
    );
  });
}
