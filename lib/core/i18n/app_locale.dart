import 'dart:ui';

/// 対応ロケール。Web の `src/i18n/config.ts` と同じ 3 つ。
///
/// **ロケールの定義はこの 1 箇所だけに置くこと。** Web 側が「ロケールを増やす時に
/// sitemap・RSS・フォントの取りこぼしが起きないように定義を 1 箇所に閉じる」方針を
/// 取っているのと同じ理由で、アプリでも配信パス・表示名・OS ロケールの対応を
/// ここに集約する。
enum AppLocale {
  ja(code: 'ja', label: '日本語'),
  en(code: 'en', label: 'English'),
  zh(code: 'zh', label: '简体中文');

  const AppLocale({required this.code, required this.label});

  /// 配信データの名前空間と URL パスに使う短いコード。
  final String code;

  /// 言語切替に出す表示名。**その言語の話者が読む名前を出す**ので翻訳しない。
  final String label;

  /// 日本語だけが特別扱いされる。配信データの名前空間（日本語はルート、他は
  /// `i18n/{code}/`）も、Web の URL 構造（日本語はルート、他はパスプレフィックス）も
  /// この区別に従う。
  bool get isDefault => this == AppLocale.ja;

  /// Web の URL に付くロケールプレフィックス。**日本語は空文字**。
  ///
  /// **`/${locale.code}` と書かないこと。** 日本語が `/ja/...` になり、Web に
  /// 存在しない URL ができる（日本語ページはルート直下のまま移設しない、という
  /// Web 側の方針は既存 URL・被リンク・過去の X 投稿・FCM 通知のリンクを
  /// 壊さないためのもので、変わらない）。
  String get pathPrefix => isDefault ? '' : '/$code';

  Locale get flutterLocale => switch (this) {
    AppLocale.ja => const Locale('ja'),
    AppLocale.en => const Locale('en'),
    // 簡体字。Web の hreflang も zh-Hans を出している
    AppLocale.zh => const Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
    ),
  };

  /// 端末の言語設定から初期ロケールを推定する。判定できなければ日本語。
  ///
  /// **優先順位リストを順に見て、最初に対応できたものを採る。** 先頭だけを見ると、
  /// 「韓国語が第1希望・英語が第2希望」の端末が英語ではなく日本語に落ちる
  /// （OS は対応言語が無い時のために複数を並べているので、先頭で打ち切ると
  /// その意図を捨てることになる）。
  ///
  /// 中国語は繁体字（zh-Hant / zh-TW / zh-HK）も `zh` に寄せる。簡体字しか
  /// 配信していないので繁体字話者には最良ではないが、英語に落とすよりは読める。
  static AppLocale fromSystem(List<Locale> preferred) {
    for (final locale in preferred) {
      final matched = _matchLanguage(locale.languageCode);
      if (matched != null) return matched;
    }
    return AppLocale.ja;
  }

  static AppLocale? _matchLanguage(String languageCode) =>
      switch (languageCode) {
        'ja' => AppLocale.ja,
        'zh' => AppLocale.zh,
        'en' => AppLocale.en,
        _ => null,
      };

  static AppLocale? fromCode(String? code) {
    for (final locale in AppLocale.values) {
      if (locale.code == code) return locale;
    }
    return null;
  }
}
