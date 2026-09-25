"""同梱する書体（Klee One / Noto Sans JP の TTF）を生成する。

**日本語は Klee One の SemiBold、英語・中国語は Noto Sans JP**（web と同じ使い分け。
理由は tonsoku-frontend-web の `src/assets/styles/main.css`）。

## 実体は web のものを使う

web（tonsoku-frontend-web）が npm で持っている配布物から作る。**別々に入手すると
版がずれて、同じ記事が web とアプリで違う字形になる。**

- Klee One: `@expo-google-fonts/klee-one` の `KleeOne_600SemiBold.ttf`（Google Fonts・OFL）
- Noto Sans JP: `@fontsource/noto-sans-jp` の `-japanese-` woff2 を素の TTF に戻す

## Klee One の太さの値を書き換える理由

**画面は SemiBold 1 つで描き、太字は縁取りで付ける**（web の判断）。アプリでは
Flutter の合成太字を縁取りの代わりにするため、ファイル自身の太さ（OS/2 の
usWeightClass）を 600 → 400 に書き換えている（理由は `pubspec.yaml` の `fonts:`）。

## Klee One を切り出す理由と範囲

web はビルド時に全ページの字が分かるので「使っている字だけ」に切り出しているが、
**アプリは後から届く記事の字を知らない。** そこで gyumesy-frontend-app の Noto と
**同じ字の集合**（fontsource の `-japanese-` が持つ 6,886 字 ＋ ラテン文字）に揃える。

丸ごと（10,178 字・7.7MB）から 6.2MB に下がる。落ちるのは Klee One だけが持つ
字（JIS 第 3・第 4 水準など）で、出てきても OS の書体で描かれる（豆腐にはならない）。

**豆腐や字形の混ざりが目立ったらここを見直すこと。**

使い方:
    python3 tool/build_fonts.py [web リポジトリのパス]
"""

import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

DEFAULT_WEB = Path.home() / "project" / "tonsoku-frontend-web"
NOTO_WEIGHTS = {"400": "Regular", "700": "Bold"}

# ラテン文字（基本・補助・拡張 A/B）。英数字と記号は必ず Klee で描く
LATIN = set(range(0x20, 0x250))


def main() -> int:
    web = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_WEB
    modules = web / "node_modules"
    noto_dir = modules / "@fontsource" / "noto-sans-jp" / "files"
    klee_src = (
        modules / "@expo-google-fonts" / "klee-one" / "600SemiBold"
        / "KleeOne_600SemiBold.ttf"
    )
    if not noto_dir.is_dir() or not klee_src.is_file():
        print(f"配布物が見つからない: {modules}\n先に web 側で yarn install すること")
        return 1

    out = Path(__file__).resolve().parent.parent / "assets" / "fonts"
    out.mkdir(parents=True, exist_ok=True)

    # ── Noto Sans JP（英語・中国語）──────────────────────
    japanese = set()
    for weight, name in NOTO_WEIGHTS.items():
        font = TTFont(noto_dir / f"noto-sans-jp-japanese-{weight}-normal.woff2")
        japanese |= set(font.getBestCmap())
        font.flavor = None  # woff2 の圧縮を外して素の TTF にする
        target = out / f"NotoSansJP-{name}.ttf"
        font.save(target)
        font.close()
        print(f"{target.name}: {target.stat().st_size // 1024}KB")

    # ── Klee One（日本語）───────────────────────────────
    klee = TTFont(klee_src)
    wanted = (japanese | LATIN) & set(klee.getBestCmap())
    options = subset.Options()
    # **字形の置き換え（縦書き・異体字）と名前表は残す。** 落とすと
    # ライセンス表記（name テーブル）まで消える
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=sorted(wanted))
    subsetter.subset(klee)
    # **ファイル自身の太さを 400 にする。** Flutter は「要求した太さがファイルの
    # 太さより 200 以上重い」時にだけ合成太字を掛けるので、600 のままだと
    # `FontWeight.bold`（700）で太くならない。web は太字を縁取り
    # （`--bold-stroke: 0.035em`）で付けていて、合成太字の量（字の大きさの
    # 1/24〜1/32）がそれとほぼ同じになる。字形は SemiBold のまま変わらない
    klee["OS/2"].usWeightClass = 400
    target = out / "KleeOne-SemiBold.ttf"
    klee.save(target)
    klee.close()
    print(f"{target.name}: {target.stat().st_size // 1024}KB（{len(wanted)} 字）")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
