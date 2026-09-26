#!/usr/bin/env bash
# マップの背景地図（assets/map/japan.pmtiles）と駅（assets/map/stations.json）を作る。
#
# **地図はアプリに同梱する**（ユーザーの判断）。松のやの店だけを載せる地図なので、
# 要るのは「陸・水域・行政境界・主な道路と鉄道・市町村名」だけ。建物・土地利用・
# 店や施設（POI）は入れない（容量の大半で、松のやの印の邪魔にもなる）。
#
# ## 材料
#
# - 背景: Protomaps の公開ビルド（OpenStreetMap 由来。© OpenStreetMap contributors）
#   から日本の範囲を切り出し、`tile-join` で層と属性を絞る
# - 駅: OpenStreetMap（Overpass API）の `railway=station`。**Protomaps の地図には
#   主要駅しか入っていない**（z12 で 1,367 件・半分は国外。多くの駅は min_zoom 13〜15）
#   ので、別に取って名前と座標だけの小さな JSON にする。アプリが印として描く
#
# ## 最大ズームは 11
#
# 実測（2026-09-25、日本全域）: 層を絞っても z12 までだと約 70MB、z11 までで約 26MB。
# 線の地図は引き伸ばしても崩れないので、店の周りを見る倍率でも z11 の形で足りる。
# **駅は z11 に入っていない**のが、駅を別に持つもう 1 つの理由。
#
# ## 使い方
#
#   tool/build_map.sh [Protomaps のビルド日 YYYYMMDD]   # 既定は 20260925
#
# 要るもの: `pmtiles`（brew install pmtiles）、`tippecanoe`（brew install tippecanoe）、
# curl、python3。作業用のファイル（数百 MB）は一時ディレクトリに作って最後に消す。
set -euo pipefail

BUILD="${1:-20260925}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/map"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 日本の範囲（沖縄〜北海道・小笠原を含む）
BBOX="122,20,154,46"
MAXZOOM=11

echo "== 背景: Protomaps ${BUILD} から切り出す（z0-${MAXZOOM}）"
pmtiles extract "https://build.protomaps.com/$BUILD.pmtiles" "$WORK/japan.pmtiles" \
  --bbox="$BBOX" --maxzoom="$MAXZOOM"

# 層ごとに残すもの。**名前は地名（places）にだけ残す**（道路・水域の名前は描かない）
#
# 地名は `name`（現地の表記）・`name:ja`・`name:en`・`name:zh-Hans`（簡体字）。
# **英語・中国語の画面に日本語を出さない**（ユーザーの決定。Issue #35）ので、
# 英語・中国語はそれぞれの言語の名前だけで描き、**無ければ描かない**
# （`lib/features/map/presentation/map_theme.dart`）。繁体字（`name:zh-Hant`）は
# アプリが簡体字しか出さないので入れない
cat > "$WORK/filter.json" <<'JSON'
{
  "roads": ["any", ["==", "kind", "rail"], ["==", "kind", "highway"],
            ["all", ["==", "kind", "major_road"], ["in", "kind_detail", "trunk", "primary"]]],
  "water": ["all", ["==", "$type", "Polygon"], ["!=", "kind", "ocean"]],
  "places": ["any", ["in", "kind", "country", "region"],
             ["all", ["==", "kind", "locality"], ["in", "kind_detail", "city", "town", "village"]]]
}
JSON

join() { # 層 属性...
  local layer="$1"; shift
  local ys=()
  for a in "$@"; do ys+=(-y "$a"); done
  tile-join -q -f -o "$WORK/L_$layer.pmtiles" -l "$layer" "${ys[@]}" \
    -J "$WORK/filter.json" "$WORK/japan.pmtiles"
}
# 海は `earth`（陸の面）の外側として描く。`water` から海を外すと約 3 割軽くなる
join earth kind
join water kind
join boundaries kind kind_detail
join roads kind kind_detail
join places kind kind_detail name name:ja name:en name:zh-Hans min_zoom

tile-join -q -f -o "$OUT/japan.pmtiles" \
  --attribution='<a href="https://www.openstreetmap.org/copyright">&copy; OpenStreetMap</a> / Protomaps' \
  "$WORK"/L_*.pmtiles

echo "== 駅: OpenStreetMap（Overpass API）から取る"
QUERY='[out:json][timeout:180];area["ISO3166-1"="JP"][admin_level=2]->.jp;(node(area.jp)["railway"="station"];node(area.jp)["public_transport"="station"]["train"="yes"];);out body;'
curl -sf -m 240 --retry 3 --retry-delay 60 --retry-all-errors -A "tonsoku-frontend-app build" \
  --data-urlencode "data=$QUERY" https://overpass-api.de/api/interpreter -o "$WORK/stations.json"

python3 - "$WORK/stations.json" "$OUT/stations.json" <<'PY'
import json, re, sys, unicodedata
src, dst = sys.argv[1], sys.argv[2]

# 仮名（平仮名・片仮名）。`name:zh` に入っているのが日本語の表記か見分ける
KANA = re.compile(r"[\u3040-\u30ff]")
# 仮名と漢字。英語名に日本語が入っていないか見る
CJK = re.compile(r"[\u3040-\u30ff\u3400-\u9fff]")


def latin_punct(s):
    # **英語・中国語の名前に残る日本語の約物を置き換える。** 中点「・」「･」は
    # 片仮名の字（U+30FB / U+FF65）で、英語名にもそのまま入っている
    # （「Zushi・Hayama」）。中国語でも人名などの区切りは「·」
    return s.replace("\u30fb", "\u00b7").replace("\uff65", "\u00b7")


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


def chinese(t):
    # 簡体字（`name:zh-Hans`）。無ければ `name:zh`。**`name:zh` は日本語の表記を
    # そのまま写しただけのものがある**ので、仮名を含むものは採らない。
    # どれも無ければ空（描かない）
    zh = t.get("name:zh-Hans") or ""
    if not zh:
        cand = t.get("name:zh") or ""
        zh = "" if KANA.search(cand) else cand
    zh = latin_punct(zh)
    return "" if KANA.search(zh) else zh


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
    row[2] = row[2] or chinese(t)
out = sorted(rows.values(), key=lambda r: (r[3], r[4]))
json.dump({"source": "© OpenStreetMap contributors",
           "fields": ["name", "name_en", "name_zh", "lat", "lon"],
           "stations": out},
          open(dst, "w"), ensure_ascii=False, separators=(",", ":"))
print(f"{len(out)} 駅（英語名なし {sum(1 for r in out if not r[1])}・"
      f"中国語名なし {sum(1 for r in out if not r[2])}）")
PY

ls -la "$OUT"
