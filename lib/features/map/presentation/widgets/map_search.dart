import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:tonsoku/core/i18n/locale_controller.dart';
import 'package:tonsoku/core/theme/app_colors.dart';
import 'package:tonsoku/features/map/domain/shop_state.dart';
import 'package:tonsoku/shared/models/shop.dart';

/// 地図の左上の検索バー（ユーザーの指定）。**仕組みは牛めしレーダー
/// （`gyumeshi-rader-app` の `shop_search_bar.dart` / `shop_search_provider.dart`）
/// を写したもの**（ユーザーの指定）:
///
/// - 探すのは**いま地図に出している店**（絞り込みを通った店。[shops]）
/// - 店舗番号（下 4 桁。[displayCode]）が一致する店を先に、続けて店名・ローマ字名の
///   部分一致。合わせて [maxResults] 件まで
/// - 候補は**入力欄にカーソルがある間だけ**出す。押すと地図をそこへ寄せて詳細を開く
/// - 絞り込みを変えたら検索語を消す（[resetKey]。レーダーの `ref.listen` と同じ）
///
/// **絞り込みのチップは検索バーの直下に置く**（[below]。レーダーの `filterChips`）。
/// 候補の一覧はバーとチップの間に出る。
class MapSearch extends ConsumerStatefulWidget {
  const MapSearch({
    required this.shops,
    required this.onShop,
    required this.resetKey,
    this.below,
    super.key,
  });

  final List<Shop> shops;
  final ValueChanged<Shop> onShop;

  /// 変わったら検索語を消す値（絞り込み）。
  final Object resetKey;

  /// バーの下に置くもの（絞り込み）。
  final Widget? below;

  static const maxResults = 20;

  @override
  ConsumerState<MapSearch> createState() => _MapSearchState();
}

class _MapSearchState extends ConsumerState<MapSearch> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(MapSearch old) {
    super.didUpdateWidget(old);
    if (old.resetKey != widget.resetKey && _controller.text.isNotEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _select(Shop shop) {
    _focus.unfocus();
    _controller.clear();
    widget.onShop(shop);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final t = ref.watch(messagesProvider);
    final results = searchShops(_controller.text, widget.shops);
    final hasText = _controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colors.border),
          ),
          elevation: 2,
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded, size: 20, color: colors.textSub),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 14, color: colors.text),
                    decoration: InputDecoration(
                      hintText: t.mapSearchHint,
                      hintStyle: TextStyle(fontSize: 14, color: colors.textSub),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
                if (hasText)
                  IconButton(
                    onPressed: _controller.clear,
                    tooltip: t.commonClose,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.textSub,
                    ),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        if (results.isNotEmpty && _focus.hasFocus) ...[
          const SizedBox(height: 4),
          Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colors.border),
            ),
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: colors.border),
                itemBuilder: (context, i) {
                  final shop = results[i];
                  // 営業していない店は薄く（地図の印と同じ）
                  final ink = shopStateOf(shop).isOpen
                      ? colors.text
                      : colors.textSub;
                  return InkWell(
                    onTap: () => _select(shop),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Text(
                            displayCode(shop),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSub,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              shop.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        if (widget.below case final below?) ...[
          const SizedBox(height: 8),
          below,
        ],
      ],
    );
  }
}

/// 店舗番号（配信の `code` の下 4 桁。牛めしレーダーの `Shop.displayCode`）。
String displayCode(Shop shop) {
  final code = shop.code;
  return code.length >= 4 ? code.substring(code.length - 4) : code;
}

/// [query] に合う店（牛めしレーダーの `searchResultsProvider` と同じ規則）。
///
/// 1. 数（0〜9999。全角の数字も読む）として読めれば、店舗番号（下 4 桁）が一致する店
/// 2. 店名の部分一致、またはローマ字名の部分一致（大文字・小文字を区別しない）
///
/// 同じ店は 1 回だけ。[MapSearch.maxResults] 件まで。
List<Shop> searchShops(String query, List<Shop> shops) {
  // **全角の数字は半角に直す**（日本語入力のまま打つと「１２０８」になる。
  // レーダーは英字の入力欄なので要らなかった）
  final q = query.trim().replaceAllMapped(
    RegExp('[０-９]'),
    (m) => String.fromCharCode(m[0]!.codeUnitAt(0) - 0xFF10 + 0x30),
  );
  if (q.isEmpty) return const [];
  final results = <Shop>[];
  final added = <String>{};

  final number = int.tryParse(q);
  if (number != null && number >= 0 && number <= 9999) {
    final padded = number.toString().padLeft(4, '0');
    for (final shop in shops) {
      if (displayCode(shop) == padded && added.add(shop.code)) {
        results.add(shop);
      }
    }
  }

  final lower = q.toLowerCase();
  for (final shop in shops) {
    if (added.contains(shop.code)) continue;
    if (shop.name.contains(q) ||
        (shop.nameRoman?.toLowerCase().contains(lower) ?? false)) {
      added.add(shop.code);
      results.add(shop);
    }
  }
  return results.length > MapSearch.maxResults
      ? results.sublist(0, MapSearch.maxResults)
      : results;
}
