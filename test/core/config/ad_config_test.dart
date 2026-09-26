import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tonsoku/core/config/ad_config.dart';

void main() {
  group('本番（release）', () {
    for (final (platform, expected) in [
      (TargetPlatform.iOS, AdConfig.productionIos),
      (TargetPlatform.android, AdConfig.productionAndroid),
    ]) {
      test('本番の ID を枠ごとに使い、テスト用の ID を混ぜない（$platform）', () {
        final config = AdConfig.resolve(release: true, platform: platform);
        for (final slot in AdSlot.values) {
          expect(config.unitId(slot), expected[slot], reason: '$slot');
          expect(
            config.unitId(slot),
            startsWith('ca-app-pub-7838125849960397/'),
            reason: '$slot',
          );
        }
        // 枠ごとに別のユニット（使い回すと位置ごとの成績が分けて見られない）
        expect(expected.values.toSet(), hasLength(AdSlot.values.length));
        expect(config.enabled, isTrue);
      });
    }

    test('ID が全部空なら SDK に触れない', () {
      const config = AdConfig(units: {});
      for (final slot in AdSlot.values) {
        expect(config.unitId(slot), isNull, reason: '$slot');
      }
      expect(config.enabled, isFalse);
    });

    test('ID を入れた枠だけ出す', () {
      const config = AdConfig(
        units: {AdSlot.anchorBanner: 'ca-app-pub-1/1', AdSlot.mapRewarded: ''},
      );
      expect(config.unitId(AdSlot.anchorBanner), 'ca-app-pub-1/1');
      expect(config.unitId(AdSlot.mapRewarded), isNull);
      expect(config.unitId(AdSlot.articleInline), isNull);
      expect(config.enabled, isTrue);
    });
  });

  group('手元（debug / profile）', () {
    test('Google 公式のテスト用 ID だけを使う（本番の広告を出さない）', () {
      for (final (platform, expected) in [
        (TargetPlatform.iOS, AdConfig.testIos),
        (TargetPlatform.android, AdConfig.testAndroid),
      ]) {
        final config = AdConfig.resolve(release: false, platform: platform);
        for (final slot in AdSlot.values) {
          expect(config.unitId(slot), expected[slot]);
          // Google のテスト用の発行元（公開されている共通のアカウント）
          expect(
            config.unitId(slot),
            startsWith('ca-app-pub-3940256099942544/'),
          );
        }
      }
    });

    test('テストの実行（kReleaseMode でない）ではテスト用 ID になる', () {
      final config = AdConfig.resolve(platform: TargetPlatform.android);
      expect(
        config.unitId(AdSlot.anchorBanner),
        AdConfig.testAndroid[AdSlot.anchorBanner],
      );
    });
  });

  test('広告を外した端末（将来の課金）は全部の枠が出ず、SDK に触れない', () {
    const config = AdConfig(units: AdConfig.testIos, adsRemoved: true);
    for (final slot in AdSlot.values) {
      expect(config.unitId(slot), isNull);
    }
    expect(config.enabled, isFalse);
  });
}
