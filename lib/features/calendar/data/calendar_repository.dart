import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/cdn/cdn_paths.dart';
import 'package:tonsoku/core/cdn/cdn_repository.dart';
import 'package:tonsoku/core/i18n/app_locale.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/features/home/data/article_providers.dart';
import 'package:tonsoku/shared/models/article_meta.dart';
import 'package:tonsoku/shared/models/calendar_event.dart';

/// `calendar.json` の取得（gyumesy-frontend-app の `CalendarRepository` を写した）。
///
/// **404 を正常系にしない。** web は「まだ配信されていない」を空で受けるが、
/// とん速の配信は 2026-09-25 時点で ja/en/zh とも 200 を返す。アプリは
/// `coupon.json` / `legal` 以外の 404 を異常として上げる方針（`CdnNotFoundException`
/// の doc）なので、ここもそれに従う。
class CalendarRepository {
  CalendarRepository({required this._cdn, required AppLocale locale})
    : _paths = CdnPaths(locale);

  final CdnRepository _cdn;
  final CdnPaths _paths;

  Stream<CalendarPayload> watchCalendar() =>
      _cdn.watch(_paths.calendar, decodeJsonObject(CalendarPayload.fromJson));

  /// 取り直す（引っ張って更新）。ランキングと同じく `fetchFresh` で温める。
  Future<void> refreshCalendar() => _cdn.fetchFresh(
    _paths.calendar,
    decodeJsonObject(CalendarPayload.fromJson),
  );
}

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => CalendarRepository(
    cdn: ref.watch(cdnRepositoryProvider),
    locale: ref.watch(localeControllerProvider),
  ),
);

final calendarProvider = StreamProvider<CalendarPayload>(
  (ref) => ref.watch(calendarRepositoryProvider).watchCalendar(),
);

/// 画面に出す予定。**`article_slug` は実在する記事のものだけ残す**
/// （gyumesy との違い。web の `buildCalendarPayload` の `articleSlugs`）。
///
/// 予定は記事より寿命が長く、**記事が消えても予定は残る**（配信が別々に作る）。
/// 信じたままにすると、押した先で記事が開けない。web はクーポンで同じ不変条件を
/// 入れたのにカレンダーだけ抜けていた、と書いている —— アプリのクーポンも
/// 記事の全件で見ている（`CouponPage`）ので、それに揃える。
///
/// **記事の全件（`index.json`）で見る。** 届く前はフィード（最新 200 件）で代える
/// （クーポンと同じ）。**どちらも届く前は落とさない** —— 一覧が無いうちに落とすと、
/// 全部の予定がいったんリンクを失ってから戻る。ずれるのは届くまでの間だけ。
///
/// **カレンダーの画面とメニューの行が同じものを見る**（別々に数えると、行は
/// 出るのに開いたら空、が起きる。ランキングの `rankingWindowsProvider` と同じ）。
final calendarEventsProvider = Provider<AsyncValue<List<CalendarEvent>>>((ref) {
  final calendar = ref.watch(calendarProvider);
  final articles =
      ref.watch(articleIndexProvider).value ?? ref.watch(feedProvider).value;
  return calendar.whenData(
    (payload) => withKnownArticles(payload.events, articles),
  );
});

/// [calendarEventsProvider] の中身。**テストから直接呼べるよう分けてある。**
///
/// [articles] が null（まだ届いていない）なら何も落とさない。
List<CalendarEvent> withKnownArticles(
  List<CalendarEvent> events,
  List<ArticleMeta>? articles,
) {
  if (articles == null) return events;
  final slugs = {for (final a in articles) a.slug};
  return [
    for (final e in events)
      if (e.articleSlug case final slug? when !slugs.contains(slug))
        e.copyWith(articleSlug: null)
      else
        e,
  ];
}
