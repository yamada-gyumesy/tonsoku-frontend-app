import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/coupon/domain/coupon_row.dart';
import 'package:tonsoku/shared/widgets/cdn_image.dart';

/// クーポンの一覧。web の `CoCouponList`（gyumesy-frontend-app の `CouponList` を
/// 写し、とん速の行の形に合わせ直した）。
///
/// **今使えるぶんとこれから始まるぶんで同じ部品を使い、別の節に置く。**
///
/// **主役はアイコン。** 各サービスの公式アプリアイコンを 48px で出す。文字を
/// 読ませる前に「PayPay の話だ」と分からせるのがこの画面の役目で、**小さくすると
/// ただの文字の羅列に戻る。汎用のピクトグラムに置き換えないこと。**
///
/// **下地が答えるのは「誰の施策か」だけなので、右下に種類バッジを重ねる**
/// （`offerBadge`）。**バッジは種類表（`CouponTypesTable`）と同じ絵**にすること
/// ―― 別の絵にすると、表を読んだ読者が対応を取れずバッジがただの飾りになる。
///
/// **見出し行は置かない。** 列が 2 つしか無く、中身を見れば「名前」と「戻り」だと
/// 分かるので、見出しと上の罫線は 1 行ぶんの高さを取るだけになる。
class CouponList extends StatelessWidget {
  const CouponList({
    required this.rows,
    required this.onOpenArticle,
    required this.onOpenLink,
    required this.onOpenImage,
    this.upcoming = false,
    super.key,
  });

  final List<CouponRow> rows;
  final ValueChanged<String> onOpenArticle;
  final ValueChanged<String> onOpenLink;
  final ValueChanged<CouponRowImage> onOpenImage;

  /// 今後の予定として出すか。true だと**開始日を名前の前に大きく出す**
  /// （この節で読者が最初に知りたいのは「いつから」）。
  final bool upcoming;

  /// 右の列の幅。**内容にまかせない。** 値の文字数は行ごとに違う（「15%」と
  /// 「70〜90円引き」）ので、固定しないと中央の列の幅が行ごとに変わり、
  /// **詳細条件の枠がバラバラの長さで並ぶ**。web の `w-[6.5rem]`。
  static const valueWidth = 104.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [for (final row in rows) _Row(row: row, list: this)],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row, required this.list});

  final CouponRow row;
  final CouponList list;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      // **行は上下中央で揃える。** アイコン・名前・数字の高さが行ごとに違うので、
      // 上揃えにすると数字だけが浮いて見える
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // **絵もバッジも無い行は枠ごと出さない**（web と同じ）
          if (row.iconUrl != null || row.badge != null) ...[
            _Icon(row: row),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: _Middle(row: row, list: list),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: CouponList.valueWidth,
            child: _Value(row: row),
          ),
        ],
      ),
    );
  }
}

class _Middle extends ConsumerWidget {
  const _Middle({required this.row, required this.list});

  final CouponRow row;
  final CouponList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final slug = row.articleSlug;
    final nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: colors.text,
    );
    // **配布元の印は名前と同じ塊に入れる。** 別の部品にして横に並べると、
    // 省略が名前にしか効かず**印だけが残って名前が全部消える**回が出る
    // （幅の狭い端末。web の実測）。1 つの文字列として切れば名前の側から削れる
    final name = Text(
      '${row.sourceMark ?? ''}${row.name}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: nameStyle,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // **日付と名前は 1 行に置く。折り返させない。** 375pt 幅だと右側に
        // 還元率が並ぶぶん残りが 200pt 前後しかなく、折り返すと日付だけが
        // 1 行を占めて、次の行の名前が別の項目に見える（web の判断）。
        // 名前のほうを省略して 1 行に収める
        Row(
          children: [
            // **今後の予定はいつからが先。** 名前の前に置くことで、
            // 縦に読んだ時に日付が列として揃う
            if (list.upcoming) ...[
              Text(
                t.couponStartBracket(row.startText),
                style: nameStyle.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: slug == null
                  ? name
                  : Semantics(
                      link: true,
                      child: GestureDetector(
                        onTap: () => list.onOpenArticle(slug),
                        child: name,
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _Terms(row: row),
        if (row.links.isNotEmpty || row.images.isNotEmpty) ...[
          const SizedBox(height: 6),
          _Chips(row: row, list: list),
        ],
      ],
    );
  }
}

/// 期限・時間帯・条件。**同じ形のラベル（太字・同色）を頭に付けて並べる。**
///
/// **期限は独立した行。** 他の情報と「・」で繋ぐと、いつまで使えるのかが語の列の
/// 中に埋もれる（ポイ活は期限で動く）。期限と時間帯は短いので 1 行に、条件はその下。
/// **項目の途中で折り返させない**（「時間帯」だけが行をまたぐと、期限の続きに見える）。
class _Terms extends ConsumerWidget {
  const _Terms({required this.row});

  final CouponRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final base = TextStyle(
      fontSize: 10,
      height: 1.625,
      color: colors.textSub,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // **ラベルは本文と同じ色で太字だけ変える**（web の
    // `font-bold text-brand-text-sub`。薄めると 10px では地に対して 4.5:1 を割る）
    final label = base.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 2,
          children: [
            _labelled(t.couponPeriodLabel, row.period, label, base),
            if (row.timeWindow case final String window)
              _labelled(t.couponTimeWindowLabel, window, label, base),
          ],
        ),
        if (row.terms.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${t.couponConditionsLabel} ', style: label),
                for (final (i, term) in row.terms.indexed) ...[
                  if (i > 0)
                    TextSpan(
                      text: ' / ',
                      style: base.copyWith(color: colors.border),
                    ),
                  TextSpan(text: term, style: base),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// **項目の途中で折り返させない。**
  Widget _labelled(String name, String value, TextStyle l, TextStyle b) =>
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$name ', style: l),
            TextSpan(text: value, style: b),
          ],
        ),
        maxLines: 1,
        softWrap: false,
      );
}

/// 恩恵を受けるための導線。**条件の下**に置く。
///
/// 期限・条件を読んでから押すものなので、名前の隣に置くと数字より先にリンクが
/// 目に入る（**行の中に別立ての導線を作らない、という一覧の原則の唯一の例外**）。
/// **無い時は何も出さない** —— リンクを本文に置かない告知が実在する。
///
/// **絵を先に出す。** QR コードは券売機の前でいちばん押してほしいもので、
/// リンクを先に回すと出どころの投稿のリンクに押し出されて 2 番目になる
/// （web で実際に起きた）。**並びの根拠は行の組み立て側（`_offerImages`）に
/// 1 つだけ置き、ここは受け取った順に並べるだけにする。**
class _Chips extends StatelessWidget {
  const _Chips({required this.row, required this.list});

  final CouponRow row;
  final CouponList list;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final image in row.images)
          image.isCode
              ? _CodeChip(
                  label: image.label,
                  onTap: () => list.onOpenImage(image),
                )
              : _Chip(
                  label: image.label,
                  icon: Icons.zoom_in,
                  button: true,
                  onTap: () => list.onOpenImage(image),
                ),
        for (final link in row.links)
          _Chip(
            label: link.label,
            // 外部へ出ることを絵で示す
            icon: Icons.open_in_new,
            button: false,
            onTap: () => list.onOpenLink(link.url),
          ),
      ],
    );
  }
}

/// 導線のチップ。**行の主役（名前・数字）より小さく**、押せることが分かる形に
/// とどめる（web の `.coupon-chip`）。
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.button,
    required this.onTap,
  });

  final String label;
  final IconData icon;

  /// 押した結果が「移動」ではない（画像を開く）か。読み上げの役割を分ける。
  final bool button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _ChipFrame(
      label: label,
      button: button,
      onTap: onTap,
      background: colors.surface,
      borderColor: colors.border,
      foreground: colors.textSub,
      // **文字と同じ大きさにすると記号が主役になる**ので小さく
      icon: Icon(icon, size: 13, color: colors.textSub),
    );
  }
}

/// QR コードのチップ。**券売機の前でいちばん押してほしいもの**なので色を変える
/// （web の `.coupon-chip-code`）。
///
/// **淡い地＋枠＋文字をカテゴリ「キャンペーン」の色で組む。** 赤は券売機への
/// 導線に対して警告色として働き悪目立ちする、黒はキツい、というユーザーの判断で
/// この色になっている。**枠は他のチップと同じ 1px を色だけ変えたもの** ―― 地だけだと
/// ダークで地色に沈む。
///
/// **絵だけ白地に載せる**（`codePlate`。ダークでは敷かない）。淡い地の上にラベルと
/// 同じ色のグリフを置くと字と絵が地続きに見えて、コードの絵だと読めない。
class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final campaign = CategoryPalette.of('campaign', colors);
    return _ChipFrame(
      label: label,
      button: true,
      onTap: onTap,
      background: campaign.tint,
      borderColor: campaign.ink,
      foreground: campaign.ink,
      // **白地は四角**（QR コードは四角い絵なので、丸い地だと角がはみ出して見える）。
      // **地はグリフにぴったり付ける** ―― 余白を入れると白の面積が増えて、
      // ラベルより四角のほうが目に付く
      icon: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.codePlate,
          borderRadius: BorderRadius.circular(2),
        ),
        child: Icon(Icons.qr_code_2, size: 12, color: campaign.ink),
      ),
    );
  }
}

class _ChipFrame extends StatelessWidget {
  const _ChipFrame({
    required this.label,
    required this.button,
    required this.onTap,
    required this.background,
    required this.borderColor,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final bool button;
  final VoidCallback onTap;
  final Color background;
  final Color borderColor;
  final Color foreground;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: button,
      link: !button,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          // web の `padding: 0.25rem 0.6rem`
          padding: const EdgeInsets.symmetric(horizontal: 9.6, vertical: 4),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, height: 1.2, color: foreground),
              ),
              const SizedBox(width: 4),
              ExcludeSemantics(child: icon),
            ],
          ),
        ),
      ),
    );
  }
}

/// 右の列。**名前（16px 太字）と釣り合う大きさにとどめる。**
/// ここだけ極端に大きくすると、行が数字の看板になって名前と期限が読まれない。
class _Value extends StatelessWidget {
  const _Value({required this.row});

  final CouponRow row;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (row.primary case final String primary)
          Text(
            primary,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.bold,
              color: colors.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        // **上限は率のすぐ下。率とセットで読む数字**なので、左の条件に混ぜると
        // 「15%」だけを見て上限に気づかない
        if (row.capText case final String cap) ...[
          const SizedBox(height: 2),
          Text(
            cap,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10,
              height: 1.25,
              color: colors.textSub,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

/// 行の絵。**下地（誰の施策か）＋ 右下の種類バッジ（種類・配布元）。**
///
/// **絵が無くてもバッジは出す。** 配信に `brands/*.webp` が無い間はアイコンが
/// null になり、入れ子にするとバッジごと消えて、X で配っているクーポンと店頭の
/// 割引が行の見た目で区別できなくなる（web の判断）。
///
/// **バッジを重ねるのはこの 48px の一覧だけ。** 最大還元率（32px）は注文方法を
/// 節の見出しが持っており、スケジュール（24px）はグリフが 8px まで落ちて読めない。
///
/// **読み上げには出さない。** 絵が示す種類は種類表が言葉で引き受けており、
/// 名前を添えると「松弁ネット2倍 松弁ネット」と同じ語を続けて読ませる。
class _Icon extends StatelessWidget {
  const _Icon({required this.row});

  final CouponRow row;

  /// 下地の一辺。
  static const _size = 48.0;

  /// バッジの一辺。
  static const _badge = 21.0;

  /// バッジの角丸。
  static const _badgeRadius = 7.0;

  /// バッジが下地からはみ出す量。
  static const _overhang = 3.0;

  /// バッジの周りに取る縁の太さ。**下の絵から切り離すためのもの。**
  static const _ring = 2.5;

  @override
  Widget build(BuildContext context) {
    final badge = row.badge;
    final icon = row.iconUrl;
    return ExcludeSemantics(
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          // **はみ出させる。** 切ると縁ごと角が落ちて、バッジが四角く見える
          clipBehavior: Clip.none,
          children: [
            if (icon != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CdnImage(url: icon, width: _size, height: _size),
              ),
            if (badge != null)
              // 縁のぶんだけさらに外へ出す（縁は見た目だけで、位置の基準は
              // あくまでバッジ本体の [_overhang]）
              Positioned(
                right: -(_overhang + _ring),
                bottom: -(_overhang + _ring),
                child: _Badge(badge: badge),
              ),
          ],
        ),
      ),
    );
  }
}

/// 種類バッジ 1 枚。**種類表（`CouponTypesTable`）と同じ絵**を出す。
class _Badge extends StatelessWidget {
  const _Badge({required this.badge});

  final CouponBadge badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      // **縁は本文の地の色で取る**（web の `ring-white dark:ring-brand-bg`）。
      // 行は背景を持たないので、**バッジの後ろにあるのは `page`**
      padding: const EdgeInsets.all(_Icon._ring),
      decoration: BoxDecoration(
        color: colors.page,
        borderRadius: BorderRadius.circular(_Icon._badgeRadius + _Icon._ring),
      ),
      child: SizedBox(
        width: _Icon._badge,
        height: _Icon._badge,
        // **`switch` 式で書く（`Map` で引かない）。** 種類を足した時に
        // コンパイラが止めてくれる。`Map` だと引けないまま素通りし、
        // 事実と違う絵がビルドもテストも通ってしまう（gyumesy の注記）
        child: switch (badge) {
          CouponBadge.x => _brand('x', colors),
          CouponBadge.tiktok => _brand('tiktok', colors),
          CouponBadge.mobileOrder => _glyph(Icons.smartphone, colors),
          CouponBadge.matsubenNet => _glyph(
            Icons.shopping_bag_outlined,
            colors,
          ),
          CouponBadge.discount => _glyph(Icons.sell_outlined, colors),
        },
      ),
    );
  }

  /// 配布元の絵。**地と罫線を敷かない**（画像が自前の地を持っているので、敷くと
  /// 内側に縮む）。**絵を置いていなければグリフに落とす**（web の `share`）。
  Widget _brand(String id, AppColors colors) {
    final key = cdnIconKey(id);
    if (key == null) return _glyph(Icons.share_outlined, colors);
    return ClipRRect(
      borderRadius: BorderRadius.circular(_Icon._badgeRadius),
      child: CdnImage(url: key, width: _Icon._badge, height: _Icon._badge),
    );
  }

  Widget _glyph(IconData icon, AppColors colors) => DecoratedBox(
    decoration: BoxDecoration(
      color: colors.surface,
      border: Border.all(color: colors.border),
      borderRadius: BorderRadius.circular(_Icon._badgeRadius),
    ),
    child: Center(child: Icon(icon, size: 14, color: colors.text)),
  );
}
