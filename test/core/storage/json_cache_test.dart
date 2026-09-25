import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/storage/json_cache.dart';

void main() {
  late Directory dir;
  late JsonCache cache;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('json_cache_test');
    cache = JsonCache(dir);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('書いたものが読める', () async {
    await cache.write('articles/feed.json', '[{"slug":"a"}]');
    final read = await cache.read('articles/feed.json');
    expect(read?.body, '[{"slug":"a"}]');
  });

  test('取得時刻を記録する', () async {
    final at = DateTime.utc(2026, 8, 23, 12);
    await withClock(Clock.fixed(at), () => cache.write('k', 'v'));
    expect((await cache.read('k'))?.fetchedAt, at);
  });

  test('未取得のキーは null', () async {
    expect(await cache.read('articles/feed.json'), isNull);
  });

  test('壊れたキャッシュは null を返す（例外を投げない）', () async {
    await cache.write('k', 'v');
    await File('${dir.path}/k').writeAsString('これは JSON ではない');
    expect(await cache.read('k'), isNull);
  });

  test('パス区切りを含むキーが別のキーと衝突しない', () async {
    // `/` を `_` に置換する実装だと両者が同じファイルに潰れる
    await cache.write('a/b', 'スラッシュ版');
    await cache.write('a_b', 'アンダースコア版');
    expect((await cache.read('a/b'))?.body, 'スラッシュ版');
    expect((await cache.read('a_b'))?.body, 'アンダースコア版');
  });

  test('clear で消える', () async {
    await cache.write('k', 'v');
    await cache.clear();
    expect(await cache.read('k'), isNull);
  });
}
