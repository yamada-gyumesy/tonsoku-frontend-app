import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/features/notifications/data/push_bootstrap.dart';

/// Android の通知チャンネル（端末の通知設定に出る）。
void main() {
  test('名前は表示言語ごと（英語・中国語に日本語を出さない。Issue #35）', () {
    expect(notificationChannelFor(AppLocale.ja).name, 'お知らせ');
    expect(notificationChannelFor(AppLocale.en).name, 'Notifications');
    expect(notificationChannelFor(AppLocale.zh).name, '通知');
  });

  // **ID を言語で変えると、言語を切り替えるたびに別のチャンネルになり、
  // 端末側のオン・オフが初期値へ戻る。** マニフェストの既定チャンネルとも割れる
  test('ID は言語に関係なく同じ（マニフェストの既定チャンネル）', () {
    final ids = {
      for (final l in AppLocale.values) notificationChannelFor(l).id,
    };
    expect(ids, {'tonsoku_default'});
  });
}
