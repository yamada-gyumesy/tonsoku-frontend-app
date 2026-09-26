"""マップの地名・駅名を言語ごとに整える（`tool/build_map.sh` から呼ぶ）。

    python build_map_names.py places <地名の層だけの .mbtiles>   # その場で書き換える
    python build_map_names.py stations <Overpass の JSON> <assets/map/stations.json>

**中国語の名前は簡体字に揃える**（ユーザーの決定）。OpenStreetMap の `name:zh-Hans`
には繁体字や日本の字体がそのまま入っているものがある（所澤市・會津若松市・長野市）。
日本の新字体（渋・沢・広）も簡体字になるよう、**日本の字体 → 繁体字 → 簡体字**
（OpenCC の `jp2t` → `t2s`）の順に通す。変換は地図を作る時だけで、アプリは
変換済みの名前を読むだけ（OpenCC をアプリに持ち込まない）。

OpenCC（`opencc` の wheel）が要る。`tool/build_map.sh` が一時ディレクトリに
venv を作って入れる。
"""

import gzip
import json
import re
import sqlite3
import sys
import unicodedata

import opencc

# 仮名（平仮名・片仮名・半角片仮名）。**「ヶ」「ヵ」「ノ」も仮名**（U+30F6・U+30F5・
# U+30CE）なので、「霞ケ関」「竜ヶ崎」「下ノ江」は仮名を含む名前として扱う
# （中国語で「ヶ」を「个」、「ノ」を「之」に読み替える決まった書き方は無い）
KANA = re.compile(r"[\u3040-\u30ff\uff65-\uff9f]")
# 仮名と漢字。英語名に日本語が入っていないか見る
CJK = re.compile(r"[\u3040-\u30ff\u3400-\u9fff]")

_JP2T = opencc.OpenCC("jp2t")
_T2S = opencc.OpenCC("t2s")

# **OpenCC の結果に手を入れる字**（実データで拾ったもの。2026-09-26、Protomaps
# 20260925 の地名と OpenStreetMap の駅を通し、GB2312 に無い字と基本多言語面の外の字を
# 洗い出して確かめた）。
#
# 通らない字: 日本の異体字・旧字で、中国語の標準の字がはっきりしているもの。
# 「辻」「栃」「峠」「畑」「込」「榊」のような日本で作られた字（国字）は中国語に
# 相当する字が無いので、そのまま残す
_EXTRA = str.maketrans({
    "姫": "姬",
    "渕": "渊",
    "嶋": "岛",
    "嶌": "岛",
    "﨑": "崎",
    "髙": "高",
    "緖": "绪",  # 緒 は jp2t で異体字の 緖 になり、t2s が通さない
    "鐡": "铁",
    "筿": "筱",  # 篠 を t2s は 筿 にするが、地名（篠山・篠栗）の簡体字は 筱
})


def _keep(src, dst):
    # **t2s の結果を採らない字。**
    # - 乾: t2s は「干」にするが、地名の 乾 は簡体字でも 乾（乾安县）
    # - 基本多言語面の外と拡張 A の字（鉾 → 𫓴、樫 → 㭴、蔄 → 𬜬）: 端末の書体に
    #   無いことが多く、豆腐になる。元の字のほうが読める
    o = ord(dst)
    return src == "乾" or o > 0xFFFF or 0x3400 <= o <= 0x4DBF


def to_hans(s):
    """日本の字体・繁体字の混ざった名前を簡体字にする。"""
    # 踊り字「々」は中国語で使わないので、前の字を繰り返す（代々木 → 代代木）
    s = re.sub(r"(.)々", r"\1\1", s)
    t = _JP2T.convert(s)
    h = _T2S.convert(t)
    # 字数が変わらない限り（OpenCC の辞書は字と字の置き換え）、字ごとに見直す
    if len(h) == len(t):
        h = "".join(src if _keep(src, dst) else dst for src, dst in zip(t, h))
    return h.translate(_EXTRA)


def latin_punct(s):
    # **英語・中国語の名前に残る日本語の約物を置き換える。** 中点「・」「･」は
    # 片仮名の字（U+30FB / U+FF65）で、英語名にもそのまま入っている
    # （「Zushi・Hayama」）。中国語でも人名などの区切りは「·」
    return s.replace("\u30fb", "\u00b7").replace("\uff65", "\u00b7")


def chinese_place(name):
    """地名の中国語名。簡体字にして、**仮名が残るものは採らない**（None。描かない）。"""
    zh = latin_punct(to_hans(name))
    return None if KANA.search(zh) else zh


# ---------------------------------------------------------------------------
# 地名（ベクタータイルの `places` 層の `name:zh-Hans`）
#
# タイル（Mapbox Vector Tile）の protobuf を必要なところだけ読み書きする。
# `tippecanoe-decode` → `tippecanoe` で作り直すと、地物の間引き・簡略化が
# 作り直しになって Protomaps の形から変わるので、**属性の値だけを差し替える**。
# 値の表（values）は鍵をまたいで共有されている（`name` と `name:zh-Hans` が同じ
# 「東京」を指す）ので、値をその場で書き換えず、`name:zh-Hans` の組だけ新しい値へ
# 付け替える。

ZH_KEY = "name:zh-Hans"


def _varint(buf, i):
    shift = result = 0
    while True:
        b = buf[i]
        i += 1
        result |= (b & 0x7F) << shift
        if b < 0x80:
            return result, i
        shift += 7


def _put_varint(n):
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def _fields(buf):
    """protobuf のフィールドを (番号, 型, 生の中身, 元のバイト列) で並べる。"""
    i = 0
    while i < len(buf):
        start = i
        tag, i = _varint(buf, i)
        num, wt = tag >> 3, tag & 7
        if wt == 0:
            val, i = _varint(buf, i)
        elif wt == 2:
            n, i = _varint(buf, i)
            val = buf[i:i + n]
            i += n
        elif wt == 5:
            val = buf[i:i + 4]
            i += 4
        elif wt == 1:
            val = buf[i:i + 8]
            i += 8
        else:
            raise ValueError(f"protobuf の型 {wt} は読めない")
        yield num, wt, val, buf[start:i]


def _ld(num, payload):
    return _put_varint(num << 3 | 2) + _put_varint(len(payload)) + bytes(payload)


def _string_value(value_msg):
    for num, wt, val, _ in _fields(value_msg):
        if num == 1 and wt == 2:
            return bytes(val).decode("utf-8")
    return None


def _rewrite_layer(layer, stats):
    parts = list(_fields(layer))
    name = next(bytes(v).decode() for n, _, v, _ in parts if n == 1)
    if name != "places":
        return None
    keys = [bytes(v).decode() for n, _, v, _ in parts if n == 3]
    values = [bytes(v) for n, _, v, _ in parts if n == 4]
    if ZH_KEY not in keys:
        return None
    zh_key = keys.index(ZH_KEY)
    index = {v: i for i, v in enumerate(values)}
    new_values = []
    remap = {}  # 元の値の番号 → 新しい値の番号（None は落とす）

    def target(vi):
        if vi in remap:
            return remap[vi]
        src = _string_value(values[vi])
        dst = None if src is None else chinese_place(src)
        if dst is None:
            stats["dropped"].add(src)
            remap[vi] = None
            return None
        if dst != src:
            stats["changed"].add((src, dst))
        msg = _ld(1, dst.encode("utf-8"))
        if msg not in index:
            index[msg] = len(values) + len(new_values)
            new_values.append(msg)
        remap[vi] = index[msg]
        return remap[vi]

    out = bytearray()
    for num, _, val, raw in parts:
        if num != 2:
            out += raw
            continue
        feature = bytearray()
        for fnum, fwt, fval, fraw in _fields(val):
            if fnum != 2 or fwt != 2:
                feature += fraw
                continue
            tags, j = [], 0
            while j < len(fval):
                t, j = _varint(fval, j)
                tags.append(t)
            new_tags = []
            for k, v in zip(tags[::2], tags[1::2]):
                if k == zh_key:
                    stats["features"] += 1
                    v = target(v)
                    if v is None:
                        continue
                new_tags += [k, v]
            feature += _ld(2, b"".join(_put_varint(t) for t in new_tags))
        out += _ld(2, feature)
    # 足した値は元の値の表の後ろに続ける（元の番号はずれない。値の番号は
    # 層の中で values が現れた順）
    for msg in new_values:
        out += _ld(4, msg)
    return bytes(out)


def _rewrite_tile(tile, stats):
    out = bytearray()
    changed = False
    for num, wt, val, raw in _fields(tile):
        if num == 3 and wt == 2:
            layer = _rewrite_layer(val, stats)
            if layer is not None:
                out += _ld(3, layer)
                changed = True
                continue
        out += raw
    return bytes(out) if changed else None


def places(mbtiles):
    stats = {"features": 0, "changed": set(), "dropped": set()}
    db = sqlite3.connect(mbtiles)
    rows = db.execute("SELECT rowid, tile_data FROM images").fetchall()
    for rowid, data in rows:
        gz = data[:2] == b"\x1f\x8b"
        tile = gzip.decompress(data) if gz else data
        new = _rewrite_tile(tile, stats)
        if new is None:
            continue
        db.execute(
            "UPDATE images SET tile_data = ? WHERE rowid = ?",
            (gzip.compress(new, mtime=0) if gz else new, rowid),
        )
    db.commit()
    db.close()
    print(
        f"地名の中国語名: 簡体字に変えた名前 {len(stats['changed'])} 種"
        f"・仮名が残って外した名前 {len(stats['dropped'])} 種"
        f"（タイル上の地名 {stats['features']} 件）"
    )
    for src, dst in sorted(stats["changed"])[:20]:
        print(f"  {src} → {dst}")
    for src in sorted(n for n in stats["dropped"] if n):
        print(f"  外した: {src}")


# ---------------------------------------------------------------------------
# 駅（`assets/map/stations.json`）


def english_punct(s):
    # 英語は全角の括弧なども半角に寄せる（NFKC）。〈〉は NFKC で変わらないので別に
    s = unicodedata.normalize("NFKC", s)
    return latin_punct(s).replace("\u3008", "(").replace("\u3009", ")")


def english(t):
    # 英語名が無ければ、日本語の読みのローマ字（`name:ja-Latn`、古い書き方の
    # `name:ja_rm`）で補う。**どれも無ければ空**（アプリはその駅を英語の画面に描かない）
    en = english_punct(t.get("name:en") or t.get("name:ja-Latn") or t.get("name:ja_rm") or "")
    # 英語名の欄に日本語がそのまま入っているものは採らない（仮名・漢字が残る）
    return "" if CJK.search(en) else en


def chinese(t, name):
    # OpenStreetMap の中国語名。簡体字（`name:zh-Hans`）、無ければ `name:zh`。
    # **`name:zh` は日本語の表記をそのまま写しただけのものがある**ので、仮名を
    # 含むものは採らない。採ったものは簡体字に揃える。無ければ空
    for cand in (t.get("name:zh-Hans"), t.get("name:zh")):
        if cand and not KANA.search(cand):
            # 一部（35 点）は「王子神谷站」「本町地铁车站」のように「站」「车站」
            # まで名前に入っている。日本語名は「駅」を付けないので揃える
            if not name.endswith("駅"):
                cand = re.sub(r"(车站|車站|站)$", "", cand)
            return chinese_place(cand) or ""
    return ""


def chinese_fallback(name, en):
    # **中国語名が無い駅**（ユーザーの決定）: 日本語名が仮名を含まない（漢字だけ）なら
    # それを簡体字にしたもの（新宿 → 新宿、渋谷 → 涩谷）、仮名を含むなら英語名。
    # 英語名も無ければ空（描かない）
    if not KANA.search(name):
        return chinese_place(name) or en
    return en


def stations(src, dst):
    rows = {}
    for e in json.load(open(src))["elements"]:
        t = e.get("tags", {})
        name = t.get("name:ja") or t.get("name")
        if not name:
            continue
        lat, lon = round(e["lat"], 5), round(e["lon"], 5)
        # **同じ名前の駅が近くに複数あれば 1 つにまとめる**（JR と地下鉄など、事業者ごとに
        # 別の点がある。地図では 1 つの駅として見せる）。約 500m の格子でまとめる。
        # **英語・中国語の名前は、まとめた点のどれかに在れば採る**（事業者ごとに
        # 付いている名前がまちまちなので、最初の点だけ見ると取りこぼす）
        key = (name, round(lat * 200), round(lon * 200))
        row = rows.setdefault(key, [name, "", "", lat, lon])
        row[1] = row[1] or english(t)
        row[2] = row[2] or chinese(t, name)
    counts = {"osm": 0, "kanji": 0, "english": 0, "none": 0}
    for row in rows.values():
        if row[2]:
            counts["osm"] += 1
            continue
        row[2] = chinese_fallback(row[0], row[1])
        if not row[2]:
            counts["none"] += 1
        elif KANA.search(row[0]):
            counts["english"] += 1
        else:
            counts["kanji"] += 1
    out = sorted(rows.values(), key=lambda r: (r[3], r[4]))
    json.dump({"source": "© OpenStreetMap contributors",
               "fields": ["name", "name_en", "name_zh", "lat", "lon"],
               "stations": out},
              open(dst, "w"), ensure_ascii=False, separators=(",", ":"))
    print(f"{len(out)} 駅（英語名なし {sum(1 for r in out if not r[1])}）")
    print(f"  中国語名: OpenStreetMap の名前 {counts['osm']}・日本語名（漢字）から "
          f"{counts['kanji']}・英語名 {counts['english']}・なし（描かない） {counts['none']}")


if __name__ == "__main__":
    cmd, *args = sys.argv[1:]
    {"places": places, "stations": stations}[cmd](*args)
