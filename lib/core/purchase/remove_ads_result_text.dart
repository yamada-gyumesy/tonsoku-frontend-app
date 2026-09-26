import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/purchase/remove_ads_controller.dart';

/// 購入・復元を押した結果を知らせる文言（メニューとマップで同じ言葉にする）。
/// **null は知らせない**（ストアのシートを本人が閉じた）。
({String text, bool isError})? removeAdsResultText(
  AppMessages t,
  RemoveAdsResult result,
) => switch (result) {
  RemoveAdsResult.purchased => (text: t.removeAdsDone, isError: false),
  RemoveAdsResult.restored => (text: t.restoreDone, isError: false),
  RemoveAdsResult.notFound => (text: t.restoreNotFound, isError: false),
  RemoveAdsResult.pending => (text: t.purchasePendingNotice, isError: false),
  RemoveAdsResult.canceled => null,
  RemoveAdsResult.failed => (text: t.purchaseFailed, isError: true),
  RemoveAdsResult.unavailable => (text: t.storeUnavailable, isError: true),
};
