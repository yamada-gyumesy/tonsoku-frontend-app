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
# 中国語の名前を簡体字に揃える OpenCC（`tool/build_map_names.py`）は、その一時
# ディレクトリの venv に入れて一緒に消す（Mac にもリポジトリにも残さない。約 13MB）。
set -euo pipefail

BUILD="${1:-20260925}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/map"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 日本の範囲（沖縄〜北海道・小笠原を含む）
BBOX="122,20,154,46"
MAXZOOM=11

echo "== OpenCC を一時的な venv に入れる"
python3 -m venv "$WORK/venv"
"$WORK/venv/bin/pip" -q install -U pip
# 手元の python3 が古いと、ソースからのビルドに落ちて失敗する（wheel だけを採る）
"$WORK/venv/bin/pip" -q install --only-binary=:all: opencc==1.2.0
NAMES=("$WORK/venv/bin/python" "$ROOT/tool/build_map_names.py")

echo "== 背景: Protomaps ${BUILD} から切り出す（z0-${MAXZOOM}）"
pmtiles extract "https://build.protomaps.com/$BUILD.pmtiles" "$WORK/japan.pmtiles" \
  --bbox="$BBOX" --maxzoom="$MAXZOOM"

# 層ごとに残すもの。**名前は地名（places）にだけ残す**（道路・水域の名前は描かない）
#
# 地名は `name`（現地の表記）・`name:ja`・`name:en`・`name:zh-Hans`（簡体字）。
# **英語・中国語の画面に日本語を出さない**（ユーザーの決定。Issue #35）ので、
# 英語・中国語はそれぞれの言語の名前だけで描き、**無ければ描かない**
# （`lib/features/map/presentation/map_theme.dart`）。繁体字（`name:zh-Hant`）は
# アプリが簡体字しか出さないので入れない。**`name:zh-Hans` にも繁体字や日本の字体が
# 混ざっている**ので、地名の層だけ一度 mbtiles に出して簡体字に揃えてから繋ぐ
# （`tool/build_map_names.py`）
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
  tile-join -q -f -o "$WORK/L_$layer.${EXT:-pmtiles}" -l "$layer" "${ys[@]}" \
    -J "$WORK/filter.json" "$WORK/japan.pmtiles"
}
# 海は `earth`（陸の面）の外側として描く。`water` から海を外すと約 3 割軽くなる
join earth kind
join water kind
join boundaries kind kind_detail
join roads kind kind_detail
# 地名は mbtiles（SQLite）に出す。python の標準だけでタイルを書き換えられる
EXT=mbtiles join places kind kind_detail name name:ja name:en name:zh-Hans min_zoom
"${NAMES[@]}" places "$WORK/L_places.mbtiles"

tile-join -q -f -o "$OUT/japan.pmtiles" \
  --attribution='<a href="https://www.openstreetmap.org/copyright">&copy; OpenStreetMap</a> / Protomaps' \
  "$WORK"/L_*.pmtiles "$WORK/L_places.mbtiles"

echo "== 駅: OpenStreetMap（Overpass API）から取る"
QUERY='[out:json][timeout:180];area["ISO3166-1"="JP"][admin_level=2]->.jp;(node(area.jp)["railway"="station"];node(area.jp)["public_transport"="station"]["train"="yes"];);out body;'
curl -sf -m 240 --retry 3 --retry-delay 60 --retry-all-errors -A "tonsoku-frontend-app build" \
  --data-urlencode "data=$QUERY" https://overpass-api.de/api/interpreter -o "$WORK/stations.json"

# 名前の整え方（英語名の補い方・中国語名の簡体字への揃え方・中国語名が無い駅の
# 扱い）は `tool/build_map_names.py`
"${NAMES[@]}" stations "$WORK/stations.json" "$OUT/stations.json"

ls -la "$OUT"
