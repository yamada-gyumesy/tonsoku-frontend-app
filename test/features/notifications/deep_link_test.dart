import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tonsoku/features/map/domain/map_link_filter.dart';
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

  /// **月もハッシュで渡る**（web の記事の「カレンダーをみる」が `#month=`）。
  test('カレンダーのハッシュの月を引き継ぐ', () {
    final t = target(
      'https://ton-soku.com/calendar/#category=campaign&month=2026-10',
    );
    expect(
      t,
      const MenuScreenTarget(
        MenuScreen.calendar,
        category: 'campaign',
        month: '2026-10',
      ),
    );
    expect(
      (t! as MenuScreenTarget).location(''),
      '/calendar?category=campaign&month=2026-10',
    );
    expect(
      target('https://ton-soku.com/en/calendar/#month=2026-10'),
      const MenuScreenTarget(MenuScreen.calendar, month: '2026-10'),
    );
  });

  /// **マップの絞り込みは web ではハッシュで渡る**（web の LP のリンク。
  /// Issue #30）。アプリの中の行き先はクエリ（[MapLinkFilter]）。
  group('マップ', () {
    test('素の /map/ はマップのタブへ（絞り込みに触らない）', () {
      expect(target('https://ton-soku.com/map/'), const RouteTarget('/map'));
      expect(target('https://ton-soku.com/map'), const RouteTarget('/map'));
      expect(target('https://ton-soku.com/zh/map/'), const RouteTarget('/map'));
    });

    test('ハッシュの絞り込みをクエリへ読み替える', () {
      final t = target(
        'https://ton-soku.com/en/map/'
        '#menu=177979,174161&brand=standalone,matsuya&include=1',
      );
      expect(t, isA<RouteTarget>());
      final location = Uri.parse((t! as RouteTarget).location);
      expect(location.path, '/map');
      expect(
        MapLinkFilter.fromQuery(location),
        MapLinkFilter.fromFragment(
          'menu=177979,174161&brand=standalone,matsuya&include=1',
        ),
      );
      expect(location.queryParameters, {
        'menu': '177979,174161',
        'brand': 'standalone,matsuya',
        'include': '1',
      });
    });

    /// **知らない値は黙って捨てる。** 読める値が無ければ素の `/map`
    test('知らない値だけなら素の /map', () {
      expect(
        target('https://ton-soku.com/map/#brand=yoshinoya&include=0&foo=1'),
        const RouteTarget('/map'),
      );
      expect(
        target('https://ton-soku.com/map/#brand=yoshinoya,mycurry'),
        const RouteTarget('/map?brand=mycurry'),
      );
    });

    /// **クエリでは読まない**（外向きの形はハッシュ 1 つ。web の LP と揃える）
    test('外の URL のクエリは読まない', () {
      expect(
        target('https://ton-soku.com/map/?menu=177979'),
        const RouteTarget('/map'),
      );
    });
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
    expect(target('https://ton-soku.com/map/extra/'), isNull);
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
  /// **iOS の名乗り（web の `apple-app-site-association`）の実物はここでは
  /// 見られない**（web のリポジトリにある）。web に置く中身の写しは
  /// `docs/deep-links.md` にあり、下のテストでマニフェストと揃える。
  test('マニフェストが名乗る面は全部アプリで開ける', () {
    for (final path in _claimedPaths()) {
      expect(
        target('https://ton-soku.com$path'),
        isNotNull,
        reason: 'AndroidManifest.xml が名乗っている $path を開けない',
      );
    }
  });

  /// **`docs/deep-links.md` の AASA（web に置く中身）も、名乗る面が全部開けて、
  /// マニフェストと同じ面を名乗っていること。**
  ///
  /// iOS は開けない面を名乗っても往復はしない（アプリ内のブラウザで開くだけ）が、
  /// **OS ごとに開く面が違う**のは web から見て説明できない。web に頼む時は
  /// この JSON をそのまま渡すので、ここで揃えておく。
  test('docs の AASA はマニフェストと同じ面を名乗り、全部開ける', () {
    final aasa = _aasaComponents();
    for (final component in aasa) {
      expect(
        target(
          'https://ton-soku.com${component.replaceAll('*', 'sample-slug')}',
        ),
        isNotNull,
        reason: 'docs/deep-links.md の AASA が名乗っている $component を開けない',
      );
    }
    // **マニフェストが名乗るものは全部 AASA も名乗る。** AASA の `*` は
    // 0 文字以上なので、`/articles/*` がマニフェストの `/articles/` も兼ねる
    bool coveredByAasa(String path) => aasa.any(
      (c) => RegExp(
        '^${c.split('*').map(RegExp.escape).join('.*')}\$',
      ).hasMatch(path),
    );
    final manifest = _manifestClaims();
    for (final claim in manifest.where((c) => !c.pattern)) {
      expect(
        coveredByAasa(claim.value),
        isTrue,
        reason: 'AndroidManifest.xml は ${claim.value} を名乗るが AASA は名乗らない',
      );
    }
    // **AASA が名乗るものは全部マニフェストも名乗る。** `X*` はマニフェストの
    // `X..*`（1 文字以上）に当たる
    for (final component in aasa) {
      final expected = component.endsWith('*')
          ? (
              value: '${component.substring(0, component.length - 1)}..*',
              pattern: true,
            )
          : (value: component, pattern: false);
      expect(
        manifest,
        contains(expected),
        reason: 'AASA は $component を名乗るが AndroidManifest.xml は名乗らない',
      );
    }
    expect(aasa.length, aasa.toSet().length, reason: 'AASA に重複がある');
  });

  /// **マップ（Issue #30）は 3 か所とも名乗る**（ロケール × 末尾スラッシュ）。
  test('マップを 3 か所とも名乗る', () {
    const paths = [
      '/map', '/map/', '/en/map', '/en/map/', '/zh/map', '/zh/map/', //
    ];
    final manifest = _claimedPaths();
    final aasa = _aasaComponents();
    for (final path in paths) {
      expect(manifest, contains(path), reason: 'AndroidManifest.xml');
      expect(aasa, contains(path), reason: 'docs/deep-links.md の AASA');
      expect(target('https://ton-soku.com$path'), const RouteTarget('/map'));
    }
  });
}

/// `docs/deep-links.md` の AASA（最初の ```json の塊）が名乗るパス。
List<String> _aasaComponents() {
  final doc = File('docs/deep-links.md').readAsStringSync();
  final block = RegExp(
    r'```json\n(\{\s*"applinks".*?)```',
    dotAll: true,
  ).firstMatch(doc);
  expect(block, isNotNull, reason: 'docs/deep-links.md に AASA が見つからない');
  final json = jsonDecode(block!.group(1)!) as Map<String, dynamic>;
  final details =
      (json['applinks'] as Map<String, dynamic>)['details'] as List<dynamic>;
  final components = [
    for (final detail in details)
      for (final c
          in (detail as Map<String, dynamic>)['components'] as List<dynamic>)
        (c as Map<String, dynamic>)['/'] as String,
  ];
  expect(components, isNotEmpty);
  return components;
}

/// App Links の intent-filter が名乗るパスを、**開ける URL の形**にして返す。
///
/// - `android:path` は完全一致なのでそのまま
/// - `android:pathPattern` は末尾 `..*`（1 文字以上）だけを許し、その位置に
///   slug を 1 つ埋める。**`android:pathPrefix` は許さない** —— 前方一致は
///   `/articles/x/y/` のような開けない深さまで名乗ってしまう
List<String> _claimedPaths() => [
  for (final claim in _manifestClaims())
    claim.pattern ? _sampleForPattern(claim.value) : claim.value,
];

/// App Links の intent-filter が名乗るもの（`android:path` / `android:pathPattern`
/// の値そのまま）。**`android:pathPrefix` は許さない**（[_claimedPaths] の doc）。
List<({String value, bool pattern})> _manifestClaims() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  // `autoVerify` が付いた 1 つ（App Links）だけを見る。ランチャーの
  // intent-filter には `data` が無い
  final filter = RegExp(
    r'<intent-filter android:autoVerify="true">(.*?)</intent-filter>',
    dotAll: true,
  ).firstMatch(manifest);
  // **名乗りが消えたら落とす。** 空で通すと、正規表現が intent-filter の書き方の
  // 変化（属性の順番など）を拾えなくなった時も黙って緑になる
  expect(filter, isNotNull, reason: 'autoVerify の intent-filter が見つからない');

  final claims = RegExp(
    r'android:path(Pattern|Prefix)?="([^"]+)"',
  ).allMatches(filter!.group(1)!).toList();
  expect(claims, isNotEmpty);

  return [
    for (final claim in claims)
      switch (claim.group(1)) {
        null => (value: claim.group(2)!, pattern: false),
        'Pattern' => (value: claim.group(2)!, pattern: true),
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
