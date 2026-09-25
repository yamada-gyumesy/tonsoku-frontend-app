import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:tonsoku/core/analytics/analytics.dart';
import 'package:tonsoku/core/analytics/screen_path.dart';

class _MockAnalytics extends Mock implements FirebaseAnalytics {}

/// GA4 へ実際に何を送っているか。
///
/// **`screen_view` でなければならない。** gyumesy がアプリから `page_view` を送っていた
/// 頃は、GA4 の統合ディメンションがアプリのイベントを読めず、「スクリーン名 /
/// スクリーン クラス」が全部 (未設定) になっていた。
///
/// **`screenName` は web の `<title>` と同じ値**にする。統合ディメンションは
/// 「ページタイトル ↔ スクリーン名」で対になるので、ここが揃っていないと
/// 同じ画面の app と web が別の行に散る（Issue #7）。
///
/// **URL を入れてはいけない。** タイトルの列に URL が並び、ホームは `/` と
/// いう読めない行になる（実際にそう出た）。
void main() {
  setUpAll(() {
    registerFallbackValue(<String, Object>{});
  });

  test('screen_view を送り、名前は web の題・クラスは web の URL', () async {
    final fa = _MockAnalytics();
    when(
      () => fa.logScreenView(
        screenName: any(named: 'screenName'),
        screenClass: any(named: 'screenClass'),
      ),
    ).thenAnswer((_) async {});

    await FirebaseAnalyticsClient(
      fa,
    ).screen(const ScreenPath(path: '/articles/abc123/', title: '新メニュー | とん速'));

    final captured = verify(
      () => fa.logScreenView(
        screenName: captureAny(named: 'screenName'),
        screenClass: captureAny(named: 'screenClass'),
      ),
    ).captured;

    expect(
      captured[0],
      '新メニュー | とん速',
      reason: 'web の <title> と同じ値でないと統合ディメンションで並ばない',
    );
    expect(
      captured[0],
      isNot(startsWith('/')),
      reason: 'URL を入れるとタイトルの列に URL が並ぶ（ホームが `/` になる）',
    );
    expect(
      captured[1],
      '/articles/abc123/',
      reason:
          'スクリーン クラスは web のページパスと同じ値。'
          'web に無い名前を入れるとパスの列で並ばない',
    );
  });

  test('page_view は送らない', () async {
    // **両方送ると表示回数が 2 倍になる。** GA4 の「表示回数」は
    // `page_view` と `screen_view` の合算なので、アプリだけ水増しされる
    final fa = _MockAnalytics();
    when(
      () => fa.logScreenView(
        screenName: any(named: 'screenName'),
        screenClass: any(named: 'screenClass'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => fa.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});

    await FirebaseAnalyticsClient(
      fa,
    ).screen(const ScreenPath(path: '/coupon/', title: '松のやのクーポン | とん速'));

    verifyNever(
      () => fa.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    );
  });

  test('アプリ固有画面は見出しではなく識別子を送る', () async {
    // **オンボーディングの見出しは 2 行組みで `\n` を含みうる**うえに、
    // 文言を直すたびに GA4 の行が別物になる。web に対応が無いので
    // 「web と同じ行に並べる」という題を使う理由も当てはまらない
    final fa = _MockAnalytics();
    when(
      () => fa.logScreenView(
        screenName: any(named: 'screenName'),
        screenClass: any(named: 'screenClass'),
      ),
    ).thenAnswer((_) async {});

    await FirebaseAnalyticsClient(fa).screen(
      const ScreenPath(
        path: '/app/onboarding/intro/',
        title: '松のや\n速報 | とん速',
        screenNameOverride: 'onboarding/intro',
        screenClassOverride: 'onboarding/intro',
      ),
    );

    final captured = verify(
      () => fa.logScreenView(
        screenName: captureAny(named: 'screenName'),
        screenClass: any(named: 'screenClass'),
      ),
    ).captured;

    expect(captured[0], 'onboarding/intro');
    expect(captured[0], isNot(contains('\n')), reason: 'スクリーン名に改行を送らない');
  });

  test('スクリーン クラスは web の URL そのもの', () {
    // **web に無い名前を入れない。** 以前は `Article` のような「画面の種類」を
    // 入れていて、web 側が URL を出すのでパスの列で並ばなかった
    const a = ScreenPath(path: '/articles/aaa/', title: 'A | とん速');
    const b = ScreenPath(path: '/articles/bbb/', title: 'B | とん速');
    expect(a.screenClass, '/articles/aaa/');
    expect(b.screenClass, '/articles/bbb/');
    expect(
      a.screenClass,
      isNot(b.screenClass),
      reason: '記事ごとに別の行になる（web と同じ粒度）',
    );
  });
}
