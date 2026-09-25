import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tonsoku/features/notifications/domain/deep_link.dart';

/// 通知から開く先。**`data.url` だけを入力にする**（`slug` / `category` から
/// 組み立て直すと、面が増えるたびにアプリ側も直さないと落とす）。
///
/// gyumesy-frontend-app の `deep_link_test.dart` を写し、とん速の画面構成
/// （カレンダー・ランキング・通知設定はメニューから開く画面・カテゴリ面は無い）に
/// 合わせ直した。
void main() {
  const host = 'ton-soku.com';
  DeepLinkTarget? target(String? url) => deepLinkTarget(url, siteHost: host);

  /// **送る側が入れてくる形**（tonsoku-backend-batch の `article_url`:
  /// `{site_public_base_url}/articles/{slug}/`）
  test('記事は記事画面へ', () {
    expect(
      target('https://ton-soku.com/articles/abc123/'),
      const RouteTarget('/articles/abc123'),
    );
  });

  test('タブの面はそのタブへ', () {
    expect(target('https://ton-soku.com/'), const RouteTarget('/'));
    expect(
      target('https://ton-soku.com/coupon/'),
      const RouteTarget('/coupon'),
    );
    expect(
      target('https://ton-soku.com/articles/'),
      const RouteTarget('/articles'),
    );
  });

  /// **カレンダー・ランキング・通知設定はメニューから開く画面。** どのタブに
  /// 積むかはシェルが決めるので、行き先ではなく種類で返る。
  test('メニューの画面は積む要求として返る', () {
    expect(
      target('https://ton-soku.com/calendar/'),
      const MenuScreenTarget(MenuScreen.calendar),
    );
    expect(
      target('https://ton-soku.com/ranking/'),
      const MenuScreenTarget(MenuScreen.ranking),
    );
    expect(
      target('https://ton-soku.com/notifications/'),
      const MenuScreenTarget(MenuScreen.notifications),
    );
    expect(
      target('https://ton-soku.com/zh/notifications'),
      const MenuScreenTarget(MenuScreen.notifications),
    );
  });

  test('メニューの画面は今のタブの接頭辞で積む', () {
    expect(
      const MenuScreenTarget(MenuScreen.notifications).location('/map'),
      '/map/notifications',
    );
    expect(const MenuScreenTarget(MenuScreen.ranking).location(''), '/ranking');
  });

  /// **web はカレンダーの絞り込みをハッシュで渡す**（クーポンの
  /// 「カレンダーをみる」が `#category=campaign`）。アプリはクエリで持つ。
  test('カレンダーのハッシュの絞り込みを引き継ぐ', () {
    final t = target('https://ton-soku.com/calendar/#category=campaign');
    expect(
      t,
      const MenuScreenTarget(MenuScreen.calendar, category: 'campaign'),
    );
    expect(
      (t! as MenuScreenTarget).location('/coupon'),
      '/coupon/calendar?category=campaign',
    );
  });

  /// **アプリの表示言語は設定であって URL ではない**（`AppRoutes` の doc）。
  test('ロケールのプレフィックスは捨てる', () {
    expect(
      target('https://ton-soku.com/en/articles/abc123/'),
      const RouteTarget('/articles/abc123'),
    );
    expect(
      target('https://ton-soku.com/zh/coupon/'),
      const RouteTarget('/coupon'),
    );
    expect(target('https://ton-soku.com/en/'), const RouteTarget('/'));
  });

  /// **アプリに画面が無い面は null。** 呼び手が外部ブラウザへ回す。
  /// 近い画面へ寄せると、押した見出しと違うものが出る。
  test('アプリに無い面は null', () {
    expect(target('https://ton-soku.com/about/'), isNull);
    expect(target('https://ton-soku.com/legal/terms/'), isNull);
    // **カテゴリの面はアプリに無い**（ホームにカテゴリのタブが無い。gyumesy との違い）
    expect(target('https://ton-soku.com/category/menu/'), isNull);
  });

  /// **配信側に面が増えても落とさない。** 知らないパスは外部ブラウザへ。
  test('知らないパスは null（外部ブラウザへ逃がす）', () {
    expect(target('https://ton-soku.com/shop/new-item/'), isNull);
    expect(target('https://ton-soku.com/articles/abc/extra/'), isNull);
    // **マップは web に無い面**なので、URL でも名乗らない
    expect(target('https://ton-soku.com/map/'), isNull);
  });

  /// **他所の URL をアプリの画面として開かない。** 出所が分からなくなる。
  test('別のホストは開かない', () {
    expect(target('https://example.com/articles/abc/'), isNull);
    // **兄弟サイトも別物**（松のやと松屋を混ぜない）
    expect(target('https://gyumesy.com/articles/abc/'), isNull);
    expect(target('https://cdn.ton-soku.com/articles/abc/'), isNull);
  });

  test('空・壊れた値でも落ちない', () {
    expect(target(null), isNull);
    expect(target(''), isNull);
    expect(target('   '), isNull);
    expect(target('not a url at all'), isNull);
    // **ホストの無い相対パスも開かない**（たまたま面の名前と一致しても）
    expect(target('/articles/abc/'), isNull);
  });

  /// 末尾スラッシュの有無で行き先が変わらない（配信は付ける約束だが、
  /// 手で作った通知が来ても同じ所へ送る）
  test('末尾スラッシュの有無で変わらない', () {
    expect(
      target('https://ton-soku.com/articles/abc123'),
      target('https://ton-soku.com/articles/abc123/'),
    );
  });

  /// **マニフェストが名乗る面は、すべて [deepLinkTarget] が開けること。**
  ///
  /// 開けない面を名乗ると、`_openPushedLink` が外部ブラウザへ逃がした
  /// ACTION_VIEW を**自分自身が受け取って際限なく往復する**（gyumesy の実測:
  /// 2000 回超の自己起動で ANR、端末の WindowManager ごと停止）。**戻ってきた
  /// 1 本と、利用者がもう一度踏んだ 1 本は URL が同じで実行時には見分けられない**
  /// ので、ここで名乗る側を縛る。
  ///
  /// **App Links はまだ名乗っていない**（リリース整備の Issue #9）。その間は
  /// 何も検査しないで通るが、intent-filter を足した瞬間から効く。
  test('マニフェストが名乗る面は全部アプリで開ける', () {
    for (final path in _claimedPaths()) {
      expect(
        target('https://ton-soku.com$path'),
        isNotNull,
        reason: 'AndroidManifest.xml が名乗っている $path を開けない',
      );
    }
  });
}

/// App Links の intent-filter が名乗るパスを、**開ける URL の形**にして返す。
/// **まだ無ければ空**（上のテストの doc）。
///
/// - `android:path` は完全一致なのでそのまま
/// - `android:pathPattern` は末尾 `..*`（1 文字以上）だけを許し、その位置に
///   slug を 1 つ埋める。**`android:pathPrefix` は許さない** —— 前方一致は
///   `/articles/x/y/` のような開けない深さまで名乗ってしまう
List<String> _claimedPaths() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  // `autoVerify` が付いた 1 つ（App Links）だけを見る。ランチャーの
  // intent-filter には `data` が無い
  final filter = RegExp(
    r'<intent-filter android:autoVerify="true">(.*?)</intent-filter>',
    dotAll: true,
  ).firstMatch(manifest);
  if (filter == null) return const [];

  final claims = RegExp(
    r'android:path(Pattern|Prefix)?="([^"]+)"',
  ).allMatches(filter.group(1)!).toList();
  expect(claims, isNotEmpty);

  return [
    for (final claim in claims)
      switch (claim.group(1)) {
        null => claim.group(2)!,
        'Pattern' => _sampleForPattern(claim.group(2)!),
        _ => fail('pathPrefix は使わないこと（${claim.group(2)}）'),
      },
  ];
}

String _sampleForPattern(String pattern) {
  expect(
    pattern,
    endsWith('/..*'),
    reason: '想定しているのは「1 文字以上」を要求する `..*` だけ（$pattern）',
  );
  return '${pattern.substring(0, pattern.length - 3)}sample-slug';
}
