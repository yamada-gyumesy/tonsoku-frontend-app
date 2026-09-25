import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/ads/ad_gateway.dart';
import 'package:tonsoku/core/ads/ads_controller.dart';
import 'package:tonsoku/core/config/ad_config.dart';
import 'package:tonsoku/core/theme/app_colors.dart';

/// バナーを 1 枚持ち、幅や ID が変わったら読み直す。アンカー・インラインの共通部分。
///
/// **読み込みの途中で画面から外れた・条件が変わった時は、届いた広告を捨てる**
/// （世代 [_generation] で見分ける。捨てないと、見えない広告が裏で残り続ける）。
mixin _BannerLoader<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  BannerHandle? banner;

  /// 読み込みが終わって、入らなかった。
  bool failed = false;

  (String, int)? _key;
  int _generation = 0;

  Future<BannerHandle?> load(AdGateway gateway, String unitId, int width);

  /// [unitId] が null（出さない）なら持っているものを捨てる。
  void request(String? unitId, int width) {
    final key = unitId == null || width <= 0 ? null : (unitId, width);
    if (key == _key) return;
    _key = key;
    _generation++;
    banner?.dispose();
    banner = null;
    failed = false;
    if (key == null) return;
    final generation = _generation;
    final gateway = ref.read(adGatewayProvider);
    load(gateway, key.$1, key.$2).then((loaded) {
      if (!mounted || generation != _generation) {
        loaded?.dispose();
        return;
      }
      setState(() {
        banner = loaded;
        failed = loaded == null;
      });
    });
  }

  @override
  void dispose() {
    _generation++;
    banner?.dispose();
    super.dispose();
  }
}

/// 下タブの上に固定するアンカーのアダプティブバナー（全タブ）。`AppShell` が
/// 下タブと一緒に `bottomNavigationBar` に積む ―― **本文はその上で終わる**ので、
/// 広告が本文を覆うことは無い（Scaffold が下の部品の高さを本文から引く）。
///
/// ---- 高さの取り方 ----
///
/// **読み込めるまでは高さを取らない（0）。入ったら広告の高さだけ取る。**
/// 先に高さを取っておけば入った瞬間の紙面の動きは消えるが、入らなかった時
/// （在庫切れ・通信不可）に**下タブの上に空の帯が残り続ける**。アンカーは画面の
/// 下端なので、入った時に本文の下端が一度上がるだけで、読んでいる位置は動かない。
/// **一度入ったら高さは保つ** ―― バナーの自動更新（SDK 側）は同じ枠の中で
/// 中身を差し替えるだけで、枠の高さは変わらない（幅と端末が同じなら常に同じ高さ）。
class AnchoredAdBanner extends ConsumerStatefulWidget {
  const AnchoredAdBanner({super.key});

  @override
  ConsumerState<AnchoredAdBanner> createState() => _AnchoredAdBannerState();
}

class _AnchoredAdBannerState extends ConsumerState<AnchoredAdBanner>
    with _BannerLoader {
  @override
  Future<BannerHandle?> load(AdGateway gateway, String unitId, int width) =>
      gateway.loadAnchoredBanner(unitId, width);

  @override
  Widget build(BuildContext context) {
    final unitId = ref.watch(adUnitProvider(AdSlot.anchorBanner));
    // 横向きではノッチの側を避ける（安全領域の内側の幅）
    final padding = MediaQuery.paddingOf(context);
    final width =
        (MediaQuery.sizeOf(context).width - padding.left - padding.right)
            .truncate();
    // build の中で読み込みを始めない（setState が build 中に走りうる）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) request(unitId, width);
    });

    final loaded = banner;
    if (unitId == null || loaded == null) return const SizedBox.shrink();
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        height: loaded.size.height,
        child: Center(
          child: SizedBox(
            width: loaded.size.width,
            height: loaded.size.height,
            child: loaded.view,
          ),
        ),
      ),
    );
  }
}

/// 記事の本文の後に置く広告の枠（web の `CoAdSlot` の `articleBottom`）。
///
/// ---- 高さの取り方 ----
///
/// **読み込んでいる間は 250 を取り、入ったら広告の高さ、入らなければ 0 に畳む。**
/// 250 は web の下限（`min-h-[250px]`。SP でよく入る 300x250 の高さ）と同じ。
/// 枠は本文の後で、開いた時はたいてい画面の外にあるので、読んでいる間に紙面が
/// 動くことは少ない。**入らなかった時は畳む** ―― web は下限の箱を残すが、アプリは
/// 在庫切れが続く時期に記事の後ろへ空白が残るのを避ける。
///
/// 高さの上限は [maxHeight]（web の `auto` は 300x600 も返すが、本文の後に
/// 画面いっぱいの広告を置かない）。
///
/// **ラベル（「広告」）は付けない。** Google 側が広告の中に描く（web と同じ）。
class InlineAdSlot extends ConsumerStatefulWidget {
  const InlineAdSlot({required this.slot, this.padding, super.key});

  final AdSlot slot;

  /// 枠の外側の余白。**広告が出ない時は余白ごと出さない。**
  final EdgeInsetsGeometry? padding;

  /// 読み込み中に取る高さ（web の下限）。
  static const reservedHeight = 250.0;

  /// 広告の高さの上限。
  static const maxHeight = 300;

  @override
  ConsumerState<InlineAdSlot> createState() => _InlineAdSlotState();
}

class _InlineAdSlotState extends ConsumerState<InlineAdSlot>
    with _BannerLoader, AutomaticKeepAliveClientMixin {
  /// **先読みの範囲の外へ出ても State を捨てない。** 記事は
  /// `ListView(children:)` なので、関連記事まで下ると枠が破棄され、上へ戻る
  /// たびに広告を要求し直す。読み込み中の 250 を取り直してから縮むので紙面が
  /// 跳び、入らなければ 250 まるごと空く（レビューで判明）。1 記事に 1 枠だけ
  /// なので、持ち続けても重くない
  @override
  bool get wantKeepAlive => true;

  @override
  Future<BannerHandle?> load(AdGateway gateway, String unitId, int width) =>
      gateway.loadInlineBanner(unitId, width, InlineAdSlot.maxHeight);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final unitId = ref.watch(adUnitProvider(widget.slot));
    if (unitId == null || failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && unitId == null) request(null, 0);
      });
      return const SizedBox.shrink();
    }
    final loaded = banner;
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.truncate();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) request(unitId, width);
          });
          if (loaded == null) {
            return const SizedBox(height: InlineAdSlot.reservedHeight);
          }
          return SizedBox(
            height: loaded.size.height,
            child: Center(
              child: SizedBox(
                width: loaded.size.width,
                height: loaded.size.height,
                child: loaded.view,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 下タブ（[nav]）の上に [AnchoredAdBanner] を積む。`AppShell` の
/// `bottomNavigationBar` に渡す。
class WithAnchoredAd extends StatelessWidget {
  const WithAnchoredAd({required this.nav, super.key});

  final Widget nav;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [const AnchoredAdBanner(), nav],
  );
}
