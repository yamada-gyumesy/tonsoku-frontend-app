#!/usr/bin/env python3
"""ストア掲載用のスクリーンショットを組み立てる。

    python3 tool/build_store_images.py            # 全部作り直す
    python3 tool/build_store_images.py --only ipad

**作りは gyumesy-frontend-app の `tool/build_store_images.py` を写した。**

**手で撮らない。** `store/marketing/*.html` を headless Chrome で指定サイズに
書き出し、ストアへ送る置き場（`ios/fastlane/screenshots/` / Android の
`images/`）へ直接置く。画面を送りながら撮ると、撮り直すたびに位置が変わって
**同じ絵を作り直せない**。

**扱うのはスクリーンショットだけではない。** フィーチャー画像（Play）・
Play のアイコン・テスター募集フォームのヘッダーも同じ意匠から出るので、
ここでまとめて作る。組版だけあって書き出しが手作業のものが残っていると、
**意匠を直した時に片方だけ古いまま**になる。

## 額縁に嵌める画面

素材（端末の中に写っている画面）は `store/source/*.png`。**これも実機で撮らず、
ここで描く**（`Screen` / `render_screen()`）。組版は `store/marketing/screens/` で、
寸法と色はアプリの実値（`screens/_screen.css` の冒頭）。

**シミュレータで撮らない。** 実機を撮る作りだと撮った日の意匠のまま素材が固まり、
iPad では間延びした実画面が出る（gyumesy が踏んだ）。それに**機種ごとにシミュレータを
立てると、ランタイムと端末のデータでディスクが数十 GB 埋まる**（とん速で実際に起きた）。

**マップも組版で描く。** 背景の地図はアプリと同じ地図データから
`tool/build_store_map.mts` が線と文字の座標まで焼いたもの（`screens/_map.js`）。
店の印は撮った日の配信の写し（`store/fixtures/app/`）。

**`store/source/*.png` を手で差し替えないこと。** このコマンドが毎回上書きする。

## なぜ端末サイズごとに HTML を分けるか

App Store は**アプリが動く端末のクラスごと**にスクリーンショットを要求する。
iPhone 6.9" は 1290×2796（縦長 2.17:1）、iPad 13" は 2048×2732（ほぼ 3:4）で、
**同じ組版を引き伸ばしても成立しない**（横に間延びするか、端末が切れる）。
アスペクトが違うものは別の組版として持つ。
"""

from __future__ import annotations

import argparse
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
MARKETING = ROOT / "store" / "marketing"
SOURCE = ROOT / "store" / "source"

CHROME = pathlib.Path(
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
)

IOS_SHOTS = ROOT / "ios" / "fastlane" / "screenshots" / "ja"
PLAY_IMAGES = (
    ROOT / "android" / "fastlane" / "metadata" / "android" / "ja-JP" / "images"
)
PLAY_SHOTS = PLAY_IMAGES / "phoneScreenshots"
# **タブレットは 7 インチと 10 インチの 2 枠。** supply はこの名前の
# フォルダしか見ない（他の名前だと無言でスキップされる）
PLAY_SEVEN_SHOTS = PLAY_IMAGES / "sevenInchScreenshots"
PLAY_TEN_SHOTS = PLAY_IMAGES / "tenInchScreenshots"
# クローズドテストの募集フォームのヘッダー。ストアには出ないが、
# **同じ意匠から作る**ので一緒に持つ
FORM = ROOT / "store" / "form"

# **gyumesy の「通知の見本」（アプリ同梱の `assets/notifications/`）はここに無い。**
# とん速は通知の見本を画像ではなくアプリの部品で描く（文言を表示言語で出し分けるため）。


class Screen:
    """額縁に嵌める**アプリの画面**を 1 枚書き出す（`store/source/` へ）。

    **窓ではなく箱で決める。** headless Chrome は viewport を 500 CSS px 未満に
    できない。窓に合わせると 402 幅の絵が 500 幅で組まれて右が欠けるので、
    **画面を固定サイズの箱にして左上から切り出す**（gyumesy と同じ）。
    """

    def __init__(self, name: str, html: str, device: str, query: str = "") -> None:
        self.name = name
        self.html = html
        self.device = device
        self.query = query

    @property
    def out(self) -> pathlib.Path:
        return SOURCE / f"{self.name}_{DEVICE_SUFFIX[self.device]}.png"


# 端末ごとの論理サイズと倍率（`screens/_screen.css` の `body[data-d]` と揃える）
DEVICES = {
    "phone": (402, 874, 3),        # iPhone 17 Pro
    "pad": (1032, 1376, 2),        # iPad 13"
    "android": (412, 915, 3),      # Pixel 級
    "androidpad": (800, 1280, 2),  # Pixel Tablet 級
}
DEVICE_SUFFIX = {"phone": "ios", "pad": "ipad", "android": "android", "androidpad": "androidpad"}

SCREENS: list[Screen] = [
    Screen(name, html, device, query)
    for device in DEVICES
    for name, html, query in (
        ("map", "screens/map.html", ""),
        ("shop", "screens/map.html", "v=shop"),
        ("home", "screens/home.html", ""),
        ("coupon", "screens/home.html", "v=coupon"),
    )
]


class Shot:
    """1 枚の書き出し。"""

    def __init__(
        self,
        group: str,
        html: str,
        out: pathlib.Path,
        width: int,
        height: int,
        query: str = "",
    ) -> None:
        self.group = group
        self.html = html
        self.out = out
        self.width = width
        self.height = height
        self.query = query


# **iPhone は 6.9" だけでよい。** 6.5" を出さなければ 6.9" が縮小して使われる
# （Screenshot specifications）。6.9" を出さない時だけ 6.5" が必須になる。
IPHONE_69 = (1290, 2796)
# **6.5" も出す。** 6.9" があれば Apple は縮小して使うが、縮小はこちらの意図
# した組版にならない（端が切れる／文字が眠くなる）。**寸法ぴったりで出すほうが
# 確実**で、同じ組版から書き出すだけなので手間も増えない
IPHONE_65 = (1284, 2778)
# **iPad はアプリが iPad で動くなら必須。** `TARGETED_DEVICE_FAMILY = "1,2"`
# （審査の端末が iPad のこともある。Issue #28）。
# 2048×2732 は 12.9"/13" の両方で受け付けられる寸法
IPAD = (2048, 2732)
# Play のスマホ。最大アスペクト 2:1 なので iPhone の 2.17:1 は流用できない
PLAY_PHONE = (1080, 1920)
# Play のタブレット。**7 インチと 10 インチは同じ 1:1.6** なので、組版は
# 1 つで足りる（`_fit.js` が寸法を合わせる）。10 インチは Pixel Tablet の実寸
PLAY_TEN = (1600, 2560)
PLAY_SEVEN = (1200, 1920)
# Play のフィーチャー画像。**この寸法しか受け付けない**
FEATURE = (1024, 500)
# Play のアイコン。**512×512 の 32bit PNG**（Play が角を丸めるので四角のまま出す）
PLAY_ICON = 512
# 募集フォームのヘッダー。Google フォームの推奨に合わせた横長
FORM_HEADER = (1600, 400)

SHOTS: list[Shot] = [
    # iPhone 6.9"
    Shot("iphone", "pair12.html", IOS_SHOTS / "iPhone69-01.png", *IPHONE_69),
    Shot("iphone", "pair12.html", IOS_SHOTS / "iPhone69-02.png", *IPHONE_69, query="?b"),
    Shot("iphone", "image3.html", IOS_SHOTS / "iPhone69-03.png", *IPHONE_69),
    Shot("iphone", "image4.html", IOS_SHOTS / "iPhone69-04.png", *IPHONE_69),
    # iPhone 6.5"（同じ組版を寸法だけ変えて書き出す）
    Shot("iphone", "pair12.html", IOS_SHOTS / "iPhone65-01.png", *IPHONE_65),
    Shot("iphone", "pair12.html", IOS_SHOTS / "iPhone65-02.png", *IPHONE_65, query="?b"),
    Shot("iphone", "image3.html", IOS_SHOTS / "iPhone65-03.png", *IPHONE_65),
    Shot("iphone", "image4.html", IOS_SHOTS / "iPhone65-04.png", *IPHONE_65),
    # iPad 13"
    Shot("ipad", "ipad.html", IOS_SHOTS / "iPad13-01.png", *IPAD, query="?n=1"),
    Shot("ipad", "ipad.html", IOS_SHOTS / "iPad13-02.png", *IPAD, query="?n=2"),
    Shot("ipad", "ipad.html", IOS_SHOTS / "iPad13-03.png", *IPAD, query="?n=3"),
    Shot("ipad", "ipad.html", IOS_SHOTS / "iPad13-04.png", *IPAD, query="?n=4"),
    # Play のスマホ
    Shot("play", "android/pair12.html", PLAY_SHOTS / "1_ja-JP_1.png", *PLAY_PHONE),
    Shot("play", "android/pair12.html", PLAY_SHOTS / "2_ja-JP_2.png", *PLAY_PHONE, query="?b"),
    Shot("play", "android/image3.html", PLAY_SHOTS / "3_ja-JP_3.png", *PLAY_PHONE),
    Shot("play", "android/image4.html", PLAY_SHOTS / "4_ja-JP_4.png", *PLAY_PHONE),
    # Play のタブレット。**同じ組版を寸法だけ変えて 2 枠に書き出す**
    *[
        Shot("playtab", "android/tablet.html", d / f"{i}_ja-JP_{i}.png",
             *size, query=f"?n={i}")
        for d, size in ((PLAY_TEN_SHOTS, PLAY_TEN), (PLAY_SEVEN_SHOTS, PLAY_SEVEN))
        for i in range(1, 5)
    ],
    # Play のフィーチャー画像。**`images/` 直下**に置く
    # （supply はサブフォルダだと無言でスキップする）
    Shot("play", "feature.html", PLAY_IMAGES / "featureGraphic.png", *FEATURE),
    # 募集フォームのヘッダー
    Shot("form", "form_header.html", FORM / "tonsoku_form_header.png", *FORM_HEADER),
]


def render(shot: Shot) -> None:
    src = MARKETING / shot.html
    if not src.exists():
        raise SystemExit(f"組版が無い: {src}")
    shot.out.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        out_tmp = pathlib.Path(tmp) / "shot.png"
        # **窓は狙いより大きく取り、左上から切り出す。** headless Chrome は
        # 頼んだ高さより内側が小さく（実測 87px）、窓に合わせると組版がそのぶん
        # 縮んで**書き出しの下に白帯が残る**。狙いの寸法は `?w=&h=` で渡す
        sep = "&" if shot.query else "?"
        query = f"{shot.query}{sep}w={shot.width}&h={shot.height}"
        cmd = [
            str(CHROME),
            "--headless",
            "--disable-gpu",
            "--hide-scrollbars",
            # **実ピクセルで書き出す。** これが無いと Retina の Mac では
            # 2 倍の画像になり、ASC が「サイズ違い」で弾く
            "--force-device-scale-factor=1",
            f"--window-size={shot.width + 40},{shot.height + 200}",
            f"--screenshot={out_tmp}",
            # 書体（同梱の Klee One）と画面の絵の読み込みを待つ
            "--virtual-time-budget=10000",
            "--allow-file-access-from-files",
            f"file://{src}{query}",
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if not out_tmp.exists():
            sys.stderr.write(res.stderr[-2000:] + "\n")
            raise SystemExit(f"書き出しに失敗: {shot.html}")

        # **アルファを落とす**（`-alpha off`）。地は全部塗ってあるので絵は
        # 変わらず、ストアに透過の要る画像は無い
        crop = subprocess.run(
            ["magick", str(out_tmp), "-crop",
             f"{shot.width}x{shot.height}+0+0", "+repage", "-alpha", "off",
             str(shot.out)],
            capture_output=True, text=True,
        )
        if crop.returncode != 0:
            sys.stderr.write(crop.stderr[-2000:] + "\n")
            raise SystemExit(
                f"切り出せなかった: {shot.html}（`brew install imagemagick`）")

    size = shot.out.stat().st_size
    print(f"WROTE {shot.out.relative_to(ROOT)} ({shot.width}x{shot.height}, {size // 1024}KB)")


def render_play_icon() -> None:
    """Play のアイコン（512）。**iOS のアイコンと同じ絵**（白いタイルに赤い丸）。

    Play は掲載のアイコンを**四角のまま受け取り、角を自分で丸める**。丸い印だけ
    （`icon_android.png`。角が透明）を出すと、丸めた角の内側に透明な隅が残って
    地の色が透ける。四角いタイルの `assets/icon/icon.png`（README の
    「アプリアイコン」で焼いたもの）を縮めて使う。
    """
    out = PLAY_IMAGES / "icon.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    res = subprocess.run(
        ["magick", str(ROOT / "assets" / "icon" / "icon.png"),
         "-resize", f"{PLAY_ICON}x{PLAY_ICON}", "-alpha", "on",
         f"PNG32:{out}"],
        capture_output=True, text=True,
    )
    if res.returncode != 0:
        sys.stderr.write(res.stderr[-2000:] + "\n")
        raise SystemExit("Play のアイコンを作れなかった")
    print(f"WROTE {out.relative_to(ROOT)} ({PLAY_ICON}x{PLAY_ICON}, {out.stat().st_size // 1024}KB)")


def render_screen(screen: Screen) -> None:
    """アプリの画面を 1 枚描く（`store/source/` へ）。"""
    src = MARKETING / screen.html
    if not src.exists():
        raise SystemExit(f"画面の組版が無い: {src}")
    screen.out.parent.mkdir(parents=True, exist_ok=True)
    css_w, css_h, ratio = DEVICES[screen.device]
    query = f"?d={screen.device}" + (f"&{screen.query}" if screen.query else "")

    with tempfile.TemporaryDirectory() as tmp:
        raw = pathlib.Path(tmp) / "raw.png"
        cmd = [
            str(CHROME), "--headless", "--disable-gpu", "--hide-scrollbars",
            f"--force-device-scale-factor={ratio}",
            # **窓は箱より大きく取る**（Chrome の下限 500 CSS px を避ける）
            f"--window-size={max(css_w + 40, 560)},{css_h + 40}",
            f"--screenshot={raw}",
            "--virtual-time-budget=10000",
            "--allow-file-access-from-files",
            f"file://{src}{query}",
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if not raw.exists():
            sys.stderr.write(res.stderr[-2000:] + "\n")
            raise SystemExit(f"画面を描けなかった: {screen.html}")
        w, h = css_w * ratio, css_h * ratio
        crop = subprocess.run(
            ["magick", str(raw), "-crop", f"{w}x{h}+0+0", "+repage", "-alpha", "off",
             str(screen.out)],
            capture_output=True, text=True,
        )
        if crop.returncode != 0:
            sys.stderr.write(crop.stderr[-2000:] + "\n")
            raise SystemExit(f"切り出せなかった: {screen.out.name}（`brew install imagemagick`）")
    print(f"SCREEN {screen.out.relative_to(ROOT)} ({w}x{h}, {screen.out.stat().st_size // 1024}KB)")


def main() -> int:
    ap = argparse.ArgumentParser()
    # **`SHOTS` のグループを増やしたらここも足す。** 綴り違いは
    # `該当なし:` で気付けるが、**存在しないと思われるグループは気付けない**
    # （`--only play` を打って Play のタブレット 8 枚だけ古いまま、が起きる）
    ap.add_argument(
        "--only",
        choices=["screens", "iphone", "ipad", "play", "playtab", "form"],
        help="screens（額縁に嵌める画面）/ iphone / ipad / play（スマホ・フィーチャー画像・"
             "アイコン）/ playtab（Play のタブレット）/ form のどれかに絞る",
    )
    args = ap.parse_args()

    if not CHROME.exists():
        raise SystemExit(f"Chrome が無い: {CHROME}")
    # **magick も必須。** `subprocess.run(["magick", ...])` は PATH に無いと
    # `FileNotFoundError` を投げるので、下の `returncode != 0` の分岐に入らず
    # 素の traceback で落ちる（＝ `brew install imagemagick` が出ない）
    if shutil.which("magick") is None:
        raise SystemExit("magick が無い: `brew install imagemagick`")

    # **画面 → 額縁の順。** 額縁は画面の PNG を嵌めるので、先に描く
    if not args.only or args.only == "screens":
        for screen in SCREENS:
            render_screen(screen)
    if args.only == "screens":
        print(f"\n{len(SCREENS)} 画面を描いた。")
        return 0

    targets = [s for s in SHOTS if not args.only or s.group == args.only]
    if not targets:
        raise SystemExit(f"該当なし: {args.only}")
    for shot in targets:
        render(shot)
    if not args.only or args.only == "play":
        render_play_icon()
    print(f"\n{len(targets)} 枚を書き出した。**ASC へ送るのは fastlane**:")
    print("  cd ios && bundle exec fastlane ios metadata skip_screenshots:false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
