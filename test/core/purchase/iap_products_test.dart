import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/purchase/purchase_gateway.dart';

/// **商品の定義の出どころは `iap_products.yaml` の 1 か所だけ**（ストアへの登録は
/// そのファイルを読む lane が行う）。アプリが読む写しが食い違うと、商品が 1 件も
/// 取れず誰も買えない ―― 型もビルドも通るので、ここで止める。
///
/// YAML の読み手は依存に足さず、行で読む（このファイルの形は単純で、足すと
/// 同梱されない依存が 1 つ増えるだけ）。
void main() {
  final yaml = File('iap_products.yaml').readAsStringSync();

  String valueOf(String key) {
    final match = RegExp(
      '^\\s*$key:\\s*(.+?)\\s*(#.*)?\$',
      multiLine: true,
    ).firstMatch(yaml);
    expect(match, isNotNull, reason: '$key が iap_products.yaml に無い');
    return match!.group(1)!;
  }

  test('アプリの商品 ID は iap_products.yaml と同じ', () {
    final ids = RegExp(
      r'^\s*-\s*product_id:\s*(\S+)',
      multiLine: true,
    ).allMatches(yaml).map((m) => m.group(1)).toList();
    expect(ids, [removeAdsProductId]);
  });

  test('価格は 550 円（ユーザーの決定）', () {
    expect(valueOf('price_jpy'), '550');
  });

  test('ストアの表示名はアプリの文言と同じ', () {
    final names = RegExp(
      r'^\s*display_name:\s*(.+?)\s*$',
      multiLine: true,
    ).allMatches(yaml).map((m) => m.group(1)).toList();
    expect(names, [
      AppMessages.ja.removeAds,
      AppMessages.en.removeAds,
      AppMessages.zh.removeAds,
    ]);
  });
}
