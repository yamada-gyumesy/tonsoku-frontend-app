import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/app_messages.dart';
import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/coupon/domain/coupon_row.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';

/// キャンペーンの種類の説明表。web の `CoCouponTypes`。
///
/// **h1 の直下に一度だけ置く。** 一覧の各行に「アプリ」「松弁ネット」と書き添えると、
/// 行ごとに同じ説明を読ませることになり、**肝心の還元率と期限が字の中に埋もれる**。
/// 用語はここで先に片付けて、下の一覧は名前・期限・数字だけで読めるようにする。
///
/// **アイコンは汎用の記号でよい。** ここで示すのは「注文の仕方」という**種類**で
/// あって特定のサービスではない。**ただし X クーポンと TikTok クーポンだけは
/// 配布元がそのサービスそのもの**なので配信の絵を使う（一覧の行と同じ絵になり
/// 対応が付く）。
///
/// **絵とグリフの対応は一覧のバッジ（`CouponList`）と同じ** ―― 片方だけ直さないこと。
class CouponTypesTable extends ConsumerWidget {
  const CouponTypesTable({super.key});

  /// 見出し列の幅。web の `w-[8.5rem]`。
  static const labelWidth = 136.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);

    // 種類の並びは web の `types` 配列と同じ
    final types = <(CouponTypeText, Widget)>[
      (t.couponTypeMobileOrder, _icon(Icons.smartphone, colors)),
      (t.couponTypeMatsubenNet, _icon(Icons.shopping_bag_outlined, colors)),
      // **絵が無ければグリフに落とす**（`cdnIconKey`）。無いものを絵にしない
      (t.couponTypeXCoupon, _brand('x', colors)),
      (t.couponTypeTiktokCoupon, _brand('tiktok', colors)),
      (t.couponTypeDiscountFair, _icon(Icons.sell_outlined, colors)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.couponTypesHeading,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 6),
        Table(
          // **罫線は全セルに引く**（記事本文の表と同じ）
          border: TableBorder.all(color: colors.border),
          columnWidths: const {
            // **見出しは折り返さない。収まらなければ列のほうが広がる**（web の
            // `w-[8.5rem] whitespace-nowrap`。表の自動レイアウトでは幅は下限で、
            // 中身が長ければ広がる）。固定幅で折り返させると「モバイルオーダー」が
            // 「モバイルオー／ダー」と語の途中で割れる（実機で出た）
            0: MaxColumnWidth(
              FixedColumnWidth(labelWidth),
              IntrinsicColumnWidth(),
            ),
            1: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            for (final (type, icon) in types)
              TableRow(
                children: [
                  // **地色は見出し列だけ。行の交互の縞は付けない**
                  // （縞は同種のデータを横に追う道具で、用語と説明の対応表には要らない）。
                  // **ダークは `bg` がページ地と同色になって見出しが消える**ので面色へ。
                  //
                  // **行の高さまで伸ばす。** 既定の `middle` だと見出しセルは
                  // 自分の高さぶんしか描かれず、説明が折り返した行で**上下に
                  // 色の付かない隙間**ができる。
                  //
                  // **`intrinsicHeight` でなければならない。** 3 通りとも別物で、
                  // 両立するのはこれだけ（`TableCell` 以外を固定して振った実測）:
                  //
                  // - `middle` —— 390dp で 2・3 行目に**塗り残し 36px**
                  // - `fill` —— 行の高さ決めからこのセルを外すので、説明が短い
                  //   行（540dp 以上）で**見出しの文字が 18px 欠ける**
                  // - `intrinsicHeight` —— 高さ決めに参加したうえで行いっぱいに
                  //   伸びるので、どちらも起きない
                  //
                  // **`Container` の `alignment` は寸法に効かない**（有無で
                  // 30 通りとも 1px も変わらない）。`middle` では `RenderTable` が
                  // 高さの制約を掛けず、`fill` / `intrinsicHeight` では高さが
                  // タイトに決まるため
                  TableCell(
                    verticalAlignment:
                        TableCellVerticalAlignment.intrinsicHeight,
                    child: Container(
                      color: colors.isDark ? colors.surface : colors.bg,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          icon,
                          const SizedBox(width: 6),
                          Text(
                            type.name,
                            softWrap: false,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.375,
                              fontWeight: FontWeight.bold,
                              color: colors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      type.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.375,
                        color: colors.text,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _icon(IconData icon, AppColors colors) =>
      Icon(icon, size: 16, color: colors.textSub);

  Widget _brand(String id, AppColors colors) {
    final key = cdnIconKey(id);
    if (key == null) return _icon(Icons.share_outlined, colors);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CdnImage(url: key, width: 16, height: 16),
    );
  }
}
