import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/cdn/cdn_paths.dart';
import 'package:tonsoku/core/cdn/cdn_repository.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/features/ranking/domain/ranking_entries.dart';
import 'package:tonsoku/shared/models/ranking.dart';

/// `ranking.json` の取得。
class RankingRepository {
  RankingRepository({required this._cdn, required AppLocale locale})
    : _paths = CdnPaths(locale);

  final CdnRepository _cdn;
  final CdnPaths _paths;

  Stream<RankingPayload> watch() => _cdn.watch(_paths.ranking, _decode);

  /// 取り直す（引っ張って更新）。
  Future<void> refreshRanking() => _cdn.fetchFresh(_paths.ranking, _decode);

  static RankingPayload _decode(String body) =>
      RankingPayload.fromJson(jsonDecode(body) as Map<String, dynamic>);
}

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepository(
    cdn: ref.watch(cdnRepositoryProvider),
    locale: ref.watch(localeControllerProvider),
  ),
);

final rankingProvider = StreamProvider<RankingPayload>(
  (ref) => ref.watch(rankingRepositoryProvider).watch(),
);

/// 突き合わせ済みの順位（窓ごと）。
///
/// **タブの出し分けと描画で同じものを見る。** 別々に数えると、導線は出るのに
/// 開いたら空、という食い違いが起きる。
final rankingWindowsProvider =
    Provider<AsyncValue<Map<RankingWindow, List<RankingEntry>>>>((ref) {
      final ranking = ref.watch(rankingProvider);
      final articles = ref.watch(articleIndexProvider);

      // **どちらも揃うまで「空」と言わない。** `index.json` は 210KB あり、
      // 先に `ranking.json`（571B）だけ届く。その間に空を出すと、通信が
      // 遅いだけなのに「ランキングが無い」に化ける
      if (ranking.hasError) {
        return AsyncValue.error(ranking.error!, StackTrace.current);
      }
      if (articles.hasError) {
        return AsyncValue.error(articles.error!, StackTrace.current);
      }
      final payload = ranking.value;
      final list = articles.value;
      if (payload == null || list == null) return const AsyncValue.loading();

      return AsyncValue.data(resolveAllWindows(payload, list));
    });
