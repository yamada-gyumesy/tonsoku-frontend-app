#!/usr/bin/env python3
"""Android の通知スモールアイコン（`ic_stat_notification`）を作る。

gyumesy-frontend-app の `tool/build_notification_icon.py` を写した（素材と置き方だけ違う）。

**素材は web と同じもの**（`tonsoku-frontend-web/public/badge.png` = web プッシュの
バッジ。`public/firebase-messaging-sw.js` の `badge:`）を `assets/icon/notification_icon.png`
に写して使う。**白い丸から字（とん速）を抜いた形**で、既に白 + 透明になっている
（web の `scripts/lib/icons.ts` の `badgeSvg`）。web の絵を変えたら写し直して回すこと。

出力:
  android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/ic_stat_notification.png

## Android のスモールアイコンの決まり

- **アルファだけがマスクとして使われ、単色で塗られる。** 色の情報は捨てられるので
  RGB は白で塗り潰す（RGBA のまま縮小すると、透明部分の RGB=黒 が混ざって縁が濁る）。
  **カラーのランチャーアイコンをそのまま指すと、全面が不透明なので白い四角になる**
  （gyumesy が踏んだ。マニフェストの `default_notification_icon` も
  `push_bootstrap.dart` の `_smallIcon` も、必ずこの絵を指すこと）。
- 24dp のキャンバスのうち **22dp のキーライン内**に収める。Android 12 以降の
  通知シェードは小アイコンを円形のチップに描くので、全幅いっぱいだと端が欠ける。

## 置き方

**丸は 1:1 なので、幅も高さもキーラインに合わせて中央に置く。** gyumesy の丼は
横長（約 1.79:1）で「幅を合わせて上下中央」だったが、式は同じで通る。

**素材は 96px しか無い。** xxxhdpi（96px）ではキーライン（88px）へわずかに縮めるだけ
なので、拡大によるぼけは起きない。

使い方:
    python3 tool/build_notification_icon.py
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/icon/notification_icon.png"
RES = ROOT / "android/app/src/main/res"

# 24dp 基準の各密度サイズ
DENSITIES = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}

SCALE = 32  # 1dp = 32px の高解像度で組んでから各密度へ縮小する
CANVAS_DP = 24
KEYLINE_INSET_DP = 1


def build_mask() -> Image.Image:
    """高解像度のアルファマスクを組む。"""
    glyph = Image.open(SOURCE).convert("RGBA").split()[3]
    glyph = glyph.crop(glyph.getbbox())  # 元アセットの余白を除く

    canvas_px = CANVAS_DP * SCALE
    keyline_px = (CANVAS_DP - KEYLINE_INSET_DP * 2) * SCALE

    # **幅をキーラインに合わせる。** 横長の素材で高さを合わせるとキャンバスをはみ出す
    width = keyline_px
    height = round(glyph.height * keyline_px / glyph.width)
    assert height <= keyline_px, "縦がキーラインを超えた。素材の比率を確認すること"
    glyph = glyph.resize((width, height), Image.LANCZOS)

    mask = Image.new("L", (canvas_px, canvas_px), 0)
    mask.paste(glyph, ((canvas_px - width) // 2, (canvas_px - height) // 2))
    return mask


def main() -> None:
    mask = build_mask()
    for name, size in DENSITIES.items():
        # **アルファだけを縮小し、RGB は白で塗る**（縁が濁らないように）
        alpha = mask.resize((size, size), Image.LANCZOS)
        icon = Image.new("RGBA", (size, size), (255, 255, 255, 0))
        icon.putalpha(alpha)
        out = RES / f"drawable-{name}" / "ic_stat_notification.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        icon.save(out)
        print(f"  {out.relative_to(ROOT)}  {size}x{size}")


if __name__ == "__main__":
    main()
