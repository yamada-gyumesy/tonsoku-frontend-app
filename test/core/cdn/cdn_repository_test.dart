import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tonsoku/core/cdn/cdn_repository.dart';
import 'package:tonsoku/core/network/cdn_client.dart';
import 'package:tonsoku/core/storage/json_cache.dart';
import 'package:mocktail/mocktail.dart';

class _MockCdnClient extends Mock implements CdnClient {}

void main() {
  group('decodeJsonList', () {
    int parse(Map<String, dynamic> json) => json['n'] as int;
    final decode = decodeJsonList(parse);

    test('読めない要素だけを落とし、残りは返す', () {
      // web は同じ場面でその記事だけを落としてビルドを続ける。1 件のために
      // 一覧ごと消える（キャッシュがあれば黙って古いまま止まる）のを防ぐ
      expect(decode('[{"n": 1}, {"n": null}, {"n": 3}]'), [1, 3]);
    });

    test('全件読めなければ例外にする（形そのものが変わった時を 0 件に潰さない）', () {
      expect(
        () => decode('[{"n": "a"}, {"n": null}]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('空の配列は空で返す（翻訳 0 件の正常な形）', () {
      expect(decode('[]'), isEmpty);
    });

    test('配列でない本文は例外にする', () {
      expect(() => decode('{"n": 1}'), throwsA(isA<TypeError>()));
    });
  });

  late Directory dir;
  late JsonCache cache;
  late _MockCdnClient client;
  late CdnRepository repository;

  const path = 'articles/feed.json';
  String identity(String body) => body;

  /// 配信が本文を返す。**`etag` の有無を問わず同じ本文を返す**
  /// （条件付き取得を使わない筋道を確かめるテストのため）。
  void serves(String body, {String? etag}) {
    when(() => client.fetch(path, etag: any(named: 'etag'))).thenAnswer(
      (_) async => CdnPayload(body: body, etag: etag, notModified: false),
    );
  }

  /// 配信が「変わっていない」（304）を返す。本文は流れない。
  void servesNotModified() {
    when(
      () => client.fetch(path, etag: any(named: 'etag')),
    ).thenAnswer((_) async => const CdnPayload.notModified());
  }

  /// **窓（[CdnRepository.freshWindow]）の外**でキャッシュを書く。
  /// 「今」書くと取り直した直後とみなされ、取得へ進まない
  Future<void> writeStaleCache(String body) =>
      withClock(Clock.fixed(DateTime.utc(2020)), () => cache.write(path, body));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cdn_repository_test');
    cache = JsonCache(dir);
    client = _MockCdnClient();
    repository = CdnRepository(client: client, cache: cache);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('watch', () {
    test('キャッシュが無ければ取得した値だけを流す', () async {
      serves('新しい');

      expect(await repository.watch(path, identity).toList(), ['新しい']);
    });

    test('取得に成功したらキャッシュへ書く', () async {
      serves('新しい');

      await repository.watch(path, identity).drain<void>();

      expect((await cache.read(path))?.body, '新しい');
    });

    test('キャッシュがあればそれを先に流し、続けて取得した値を流す', () async {
      await writeStaleCache('古い');
      serves('新しい');

      expect(await repository.watch(path, identity).toList(), ['古い', '新しい']);
    });

    test('キャッシュを流し終えていれば、取得に失敗してもエラーにしない', () async {
      await writeStaleCache('古い');
      when(
        () => client.fetch(path),
      ).thenThrow(const CdnFetchException(path, 'timeout'));

      expect(await repository.watch(path, identity).toList(), ['古い']);
    });

    test('キャッシュが無く取得にも失敗したらエラーを流す', () async {
      when(
        () => client.fetch(path),
      ).thenThrow(const CdnNotFoundException(path));

      expect(
        repository.watch(path, identity),
        emitsError(isA<CdnNotFoundException>()),
      );
    });

    test('キャッシュのデコードに失敗したら無視して取得へ進む', () async {
      // 配信データの形が変わった後にアプリを更新した状況
      await writeStaleCache('これは JSON ではない');
      serves('[]');

      final decode = decodeJsonList<Map<String, dynamic>>((json) => json);
      final results = await repository.watch(path, decode).toList();

      expect(results, hasLength(1));
      expect(results.single, isEmpty);
    });

    test('デコードできない配信データはキャッシュへ書かない', () async {
      serves('壊れている');
      final decode = decodeJsonList<Map<String, dynamic>>((json) => json);

      await expectLater(
        repository.watch(path, decode),
        emitsError(isA<Object>()),
      );
      // 壊れたものを焼き付けると、オフライン時にそれを読み続けてしまう
      expect(await cache.read(path), isNull);
    });
  });

  group('取り直した直後は二重に取得しない', () {
    // 引っ張って更新・アクティブ復帰は fetchFresh でキャッシュを温めてから
    // provider を貼り直す。窓が無いと 1 回の取り直しで全パスを 2 回 GET する
    test('取得したばかりのキャッシュなら取りに行かない', () async {
      serves('新しい');
      await repository.fetchFresh(path, identity);
      clearInteractions(client);

      expect(await repository.watch(path, identity).toList(), ['新しい']);
      verifyNever(() => client.fetch(path, etag: any(named: 'etag')));
    });

    test('壊れたキャッシュが窓の内側でも取りに行く', () async {
      // `servedFromCache` を条件から外すと、ここで 1 件も流さないまま
      // 完了し、画面が永久に読み込み中になる
      await cache.write(path, 'これは JSON ではない');
      serves('[]');

      final decode = decodeJsonList<Map<String, dynamic>>((json) => json);
      final results = await repository.watch(path, decode).toList();

      expect(results, hasLength(1));
      verify(() => client.fetch(path, etag: any(named: 'etag'))).called(1);
    });

    test('時計が進んでいた頃のキャッシュは窓に入れない', () async {
      // fetchedAt が未来だと経過が負になり、時計を直した後もずっと
      // 「取ったばかり」と判定されてしまう
      await withClock(
        Clock.fixed(DateTime.utc(2030)),
        () => cache.write(path, '未来に書かれた'),
      );
      serves('新しい');

      expect(await repository.watch(path, identity).toList(), [
        '未来に書かれた',
        '新しい',
      ]);
    });

    test('窓を過ぎたキャッシュなら取りに行く', () async {
      await writeStaleCache('古い');
      serves('新しい');

      expect(await repository.watch(path, identity).toList(), ['古い', '新しい']);
    });
  });

  group('購読を途中で解除しても書き込みが飛ばない', () {
    // `async*` の yield は、購読側が値を受け取った直後に解除するとそこで生成関数が
    // 終わり、後続の await が実行されない。書き込みを yield の後ろに置くと
    // 「値は返るのにキャッシュだけ残らない」状態になり、そのパスの
    // stale-while-revalidate が黙って永久に効かなくなる。
    // toList() / drain() は購読を続けるのでこの穴を通り抜ける

    test('first で受け取ってもキャッシュへ書く', () async {
      serves('新しい');

      expect(await repository.watch(path, identity).first, '新しい');
      expect((await cache.read(path))?.body, '新しい');
    });

    test('take(2) で受け取ってもキャッシュへ書く', () async {
      // 2 回 yield する設計なので、take(2) はむしろ自然な書き方
      await writeStaleCache('古い');
      serves('新しい');

      final values = await repository.watch(path, identity).take(2).toList();

      expect(values, ['古い', '新しい']);
      expect((await cache.read(path))?.body, '新しい');
    });

    test('await for + break でもキャッシュへ書く', () async {
      serves('新しい');

      await for (final _ in repository.watch(path, identity)) {
        break;
      }

      expect((await cache.read(path))?.body, '新しい');
    });
  });

  group('キャッシュへ書けない時', () {
    /// 書き込めないキャッシュ（ファイルの中にディレクトリを作ろうとして失敗する）。
    /// 容量不足や権限で write が落ちる状況の代わり。
    Future<CdnRepository> brokenCacheRepository() async {
      final blocker = File('${dir.path}/blocker');
      await blocker.writeAsString('ここはファイルなのでディレクトリを掘れない');
      return CdnRepository(
        client: client,
        cache: JsonCache(Directory('${blocker.path}/nested')),
      );
    }

    test('取得できた値は、書き込みに失敗しても流す', () async {
      // 書き込み失敗で握り潰すと、通信が生きているのに一覧が更新されなくなる
      serves('新しい');
      final broken = await brokenCacheRepository();

      expect(await broken.watch(path, identity).toList(), ['新しい']);
    });
  });

  /// **持っている `ETag` を載せて聞き、変わっていなければ本文を流さない。**
  ///
  /// 記事は後から直されるので取り直しは必ず要るが、毎回まるごと落とすと R2 に
  /// 無駄がかかる。**変わったかどうかだけを聞く**（実測で 304 は 0 バイト）。
  group('条件付き取得', () {
    test('キャッシュの ETag を載せて聞く', () async {
      await withClock(
        Clock.fixed(DateTime.utc(2020)),
        () => cache.write(path, '古い', etag: '"abc"'),
      );
      servesNotModified();

      await repository.watch(path, identity).toList();

      verify(() => client.fetch(path, etag: '"abc"')).called(1);
    });

    test('変わっていなければキャッシュの値だけを流す', () async {
      await withClock(
        Clock.fixed(DateTime.utc(2020)),
        () => cache.write(path, '古い', etag: '"abc"'),
      );
      servesNotModified();

      expect(await repository.watch(path, identity).toList(), ['古い']);
    });

    /// **確かめた事実を残す。** 残さないと `fetchedAt` が古いままで、
    /// 次の表示でまた問い合わせる。
    test('変わっていなければ取得時刻を入れ直す', () async {
      await withClock(
        Clock.fixed(DateTime.utc(2020)),
        () => cache.write(path, '古い', etag: '"abc"'),
      );
      servesNotModified();

      await repository.watch(path, identity).toList();

      // 2 回目は窓の内側なので問い合わせない
      await repository.watch(path, identity).toList();
      verify(() => client.fetch(path, etag: '"abc"')).called(1);
    });

    test('変わっていなければ「変わった」と言わない', () async {
      await withClock(
        Clock.fixed(DateTime.utc(2020)),
        () => cache.write(path, '古い', etag: '"abc"'),
      );
      servesNotModified();

      expect(await repository.fetchFreshIfChanged(path, identity), isFalse);
    });

    /// **キャッシュを流せなかった時は条件を付けない。**
    ///
    /// 封筒は無事でも中身が decode できないことがある（必須項目を足した
    /// アプリを配った後など）。その状態で `ETag` を載せると、配信が変わって
    /// いない限り 304 が返り、**1 件も流さないままストリームが閉じて画面が
    /// 永久に読み込み中になる**（再起動しても `invalidate` しても同じ）。
    test('キャッシュを解けなかったら ETag を載せずに本文を貰う', () async {
      await withClock(
        Clock.fixed(DateTime.utc(2020)),
        () => cache.write(path, '解けない', etag: '"abc"'),
      );
      serves('新しい', etag: '"xyz"');

      // decode が通らないキャッシュ
      String onlyNew(String body) {
        if (body == '解けない') throw const FormatException('解けない');
        return body;
      }

      expect(await repository.watch(path, onlyNew).toList(), ['新しい']);
      verify(() => client.fetch(path, etag: null)).called(1);
    });

    /// **ETag を持たないキャッシュも読めること。** 付ける前に書かれたものが
    /// 端末に残っている。条件を付けずに取り直すだけ。
    test('ETag を持たないキャッシュは条件を付けずに取り直す', () async {
      await writeStaleCache('古い');
      serves('新しい', etag: '"xyz"');

      expect(await repository.watch(path, identity).toList(), ['古い', '新しい']);
      verify(() => client.fetch(path, etag: null)).called(1);
    });
  });

  /// **「キャッシュがあれば取り直さない」取得口は置かない。**
  ///
  /// 以前 `fetchOnce` があり、関連記事のメタがそれで解決されていた。配信が
  /// 一時的に崩れた瞬間の本文を掴むと、**配信が直ってもアプリは永久に壊れた
  /// 行を出し続ける**（実機で発生。再インストール以外に直す手が無かった）。
  ///
  /// 取得口を [CdnRepository.watch] だけにしたので、**古いキャッシュを流した
  /// 後に必ず取り直しが走る**。ここではその性質を固定する。
  test('古いキャッシュを流した後、必ず取り直す', () async {
    await writeStaleCache('壊れた本文');
    serves('直った本文');

    expect(await repository.watch(path, identity).toList(), ['壊れた本文', '直った本文']);
    verify(() => client.fetch(path, etag: any(named: 'etag'))).called(1);
  });

  /// **アクティブ復帰で、変わっていない物を貼り直さないために要る。**
  /// 貼り直すとストリームの作り直し・キャッシュの読み直し・JSON の再デコードが
  /// 走る。配信データは大半の復帰で変わっていないので、変わった物だけに絞る。
  group('fetchFreshIfChanged', () {
    test('本文が変わっていなければ false', () async {
      await writeStaleCache('同じ');
      serves('同じ');

      expect(await repository.fetchFreshIfChanged(path, identity), isFalse);
    });

    test('本文が変わっていれば true', () async {
      await writeStaleCache('古い');
      serves('新しい');

      expect(await repository.fetchFreshIfChanged(path, identity), isTrue);
    });

    test('キャッシュが無ければ true', () async {
      serves('新しい');

      expect(await repository.fetchFreshIfChanged(path, identity), isTrue);
    });

    test('変わっていなくてもキャッシュは温め直す', () async {
      await writeStaleCache('同じ');
      serves('同じ');

      await repository.fetchFreshIfChanged(path, identity);
      // 窓の中に入るので、次の `watch` は取りに行かない
      expect(await repository.watch(path, identity).toList(), ['同じ']);
      verify(() => client.fetch(path, etag: any(named: 'etag'))).called(1);
    });

    /// **壊れた本文でキャッシュを上書きしない。** 上書きすると、次の起動で
    /// 壊れた値が画面に出る。
    test('decode が投げたらキャッシュを書き換えない', () async {
      await writeStaleCache('元の');
      serves('壊れた');

      await expectLater(
        repository.fetchFreshIfChanged(path, (body) {
          if (body == '壊れた') throw const FormatException();
          return body;
        }),
        throwsA(isA<FormatException>()),
      );
      expect((await cache.read(path))?.body, '元の');
    });
  });
}
