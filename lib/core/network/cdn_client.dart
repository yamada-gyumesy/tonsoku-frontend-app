import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/config/app_config.dart';
import 'package:tonsoku/core/config/app_config_provider.dart';

/// 配信データが存在しない（404）。
///
/// **呼び出し側がこれを正常系として扱ってよいのは `coupon.json` と `legal/*.md`
/// だけ。** 一覧系は翻訳 0 件でも空配列で 200 が返る契約なので、そこで 404 が出たら
/// 配信の異常であり、握り潰すと「データが無い」と「壊れている」の区別がつかなくなる。
///
/// 404 を許すこの 2 つも、**2026-08-23 時点の本番は全ロケールで 200 を返す**
/// （coupon は 66KB の実データ、legal は 3 ページとも配信済み）。それでも
/// 正常系として扱うのは、配信側がレビュー前や生成失敗時に落とすことがあると
/// 運用ドキュメントに明記されているため。空表示に落として画面は出す。
///
/// **アプリは web より厳しい側に倒してある。** web の取得層（`src/utils/data.ts`）は
/// 全ての 404 を黙って空扱いにするが、アプリは上記 2 つ以外の 404 を例外として上げる。
/// 配信の異常を「データが無い」と取り違えると、原因の分からない空画面が残るため。
class CdnNotFoundException implements Exception {
  const CdnNotFoundException(this.path);

  final String path;

  @override
  String toString() => 'CdnNotFoundException: $path';
}

/// 配信データの取得に失敗した（通信断・タイムアウト・5xx など）。
class CdnFetchException implements Exception {
  const CdnFetchException(this.path, this.cause);

  final String path;
  final Object cause;

  @override
  String toString() => 'CdnFetchException: $path ($cause)';
}

/// 配信データの取得結果。**変わっていなければ本文は入らない。**
class CdnPayload {
  const CdnPayload({
    required this.body,
    required this.etag,
    required this.notModified,
  });

  /// 変わっていなかった（304）。**[body] は空**で、呼び出し側は
  /// キャッシュの本文を使い続ける。
  const CdnPayload.notModified() : body = '', etag = null, notModified = true;

  final String body;

  /// 配信元が返した `ETag`。次の取得で `If-None-Match` に載せる。
  final String? etag;

  final bool notModified;
}

/// R2 から配信データを取ってくるだけの薄いクライアント。
///
/// 画面から直接触らせず、必ず Repository 層を経由させる。
class CdnClient {
  CdnClient({required AppConfig config, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: config.cdnBaseUrl,
              // 配信データは静的ファイルなので、待たされる = 電波が悪い。
              // 長く待つよりキャッシュを見せて裏で諦めるほうが体感がよい
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              // JSON も md も文字列で受け取り、パースは Repository 層に寄せる。
              // dio の自動 JSON パースに任せると、キャッシュへ書き戻す時に
              // もう一度 encode することになって無駄が出る
              responseType: ResponseType.plain,
              // **304 を成功として受け取る。** 既定は 2xx だけなので、
              // これが無いと「変わっていない」が例外になり、毎回まるごと
              // 落とすのと変わらなくなる
              validateStatus: (status) =>
                  status != null && (status < 300 || status == 304),
            ),
          );

  final Dio _dio;

  /// [path] は `articles/feed.json` のような CDN ルートからの相対パス。
  ///
  /// **[etag] を渡すと条件付き取得になる。** 変わっていなければ配信元は 304 を
  /// 返し、本文は流れない（実測 0 バイト）。**記事は後から直されるので取り直しは
  /// 必ず要るが、毎回まるごと落とすと R2 に無駄がかかる**ので、変わったかどうか
  /// だけを聞く。
  Future<CdnPayload> fetch(String path, {String? etag}) async {
    try {
      final response = await _dio.get<String>(
        '/$path',
        options: etag == null
            ? null
            : Options(headers: {'If-None-Match': etag}),
      );
      if (response.statusCode == 304) return const CdnPayload.notModified();
      return CdnPayload(
        body: response.data ?? '',
        etag: response.headers.value('etag'),
        notModified: false,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw CdnNotFoundException(path);
      }
      throw CdnFetchException(path, e);
    }
  }
}

final cdnClientProvider = Provider<CdnClient>(
  (ref) => CdnClient(config: ref.watch(appConfigProvider)),
);
