import 'package:tonsoku/core/i18n/app_locale.dart';

/// アプリ全体の環境設定。
///
/// Web（`tonsoku-frontend-web`）の `src/config.ts` に相当する。開発版 flavor は
/// 作らない方針なので構成は prod ひとつだけで、ローカルの mock CDN を見たい時は
/// `--dart-define=CDN_BASE_URL=http://localhost:4000` で差し替える
/// （gyumesy-frontend-app と同じ）。
class AppConfig {
  const AppConfig({required this.cdnBaseUrl, required this.siteBaseUrl});

  /// 配信データ（JSON・画像）の取得元。R2 バケット `tonsoku-cdn` のカスタムドメイン。
  ///
  /// **アプリは R2 の CORS に縛られない。** CORS は `https://ton-soku.com` 限定だが、
  /// あれはブラウザだけの仕組みなので、ネイティブの取得は素通りする。
  final String cdnBaseUrl;

  /// Web 版のオリジン。記事のシェア URL と、アプリに画面を持たない
  /// 「とん速とは」「法務」への遷移先を組み立てるのに使う。
  final String siteBaseUrl;

  static const _cdnOverride = String.fromEnvironment('CDN_BASE_URL');
  static const _siteOverride = String.fromEnvironment('SITE_BASE_URL');

  /// 末尾スラッシュ付きで渡されてもパス結合が `//` にならないよう正規化する。
  static String _normalize(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// CDN 上のリソースを指す絶対 URL を作る。
  ///
  /// **配信データには 2 つの表現が混ざりうる。** 記事メタデータの `thumbnail` 等は
  /// 絶対 URL で入っており、`CdnPaths` が組み立てるのは CDN ルートからの相対パス。
  /// 見分ける印が無いので、**画像やファイルの URL は必ずここを通す**こと
  /// （web の `src/utils/cdn.ts` と同じ形）。
  String cdnUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    final suffix = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    return '$cdnBaseUrl$suffix';
  }

  /// Web 版の同じページを指す絶対 URL。シェアと、アプリに画面が無いページ
  /// （とん速とは・法務）への遷移に使う。
  ///
  /// **日本語はルート、追加ロケールはパスプレフィックス**という web の URL 構造に従う
  /// （配信データの名前空間とは別の話なので `CdnPaths` とは分けてある）。
  ///
  /// プレフィックスの組み立ては [AppLocale.pathPrefix] に寄せてある。呼び出し側に
  /// 文字列を作らせると、日本語で `/ja/...` という存在しない URL ができる。
  String siteUrl(String path, AppLocale locale) {
    final suffix = path.startsWith('/') ? path : '/$path';
    return '$siteBaseUrl${locale.pathPrefix}$suffix';
  }

  factory AppConfig.resolve() => AppConfig(
    cdnBaseUrl: _normalize(
      _cdnOverride.isEmpty ? 'https://cdn.ton-soku.com' : _cdnOverride,
    ),
    siteBaseUrl: _normalize(
      _siteOverride.isEmpty ? 'https://ton-soku.com' : _siteOverride,
    ),
  );
}
