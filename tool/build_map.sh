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
join places kind kind_detail name name:ja name:en min_zoom

tile-join -q -f -o "$OUT/japan.pmtiles" \
  --attribution='<a href="https://www.openstreetmap.org/copyright">&copy; OpenStreetMap</a> / Protomaps' \
  "$WORK"/L_*.pmtiles

echo "== 駅: OpenStreetMap（Overpass API）から取る"
QUERY='[out:json][timeout:180];area["ISO3166-1"="JP"][admin_level=2]->.jp;(node(area.jp)["railway"="station"];node(area.jp)["public_transport"="station"]["train"="yes"];);out body;'
curl -sf -m 240 --retry 3 --retry-delay 60 --retry-all-errors -A "tonsoku-frontend-app build" \
  --data-urlencode "data=$QUERY" https://overpass-api.de/api/interpreter -o "$WORK/stations.json"

python3 - "$WORK/stations.json" "$OUT/stations.json" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
rows = {}
for e in json.load(open(src))["elements"]:
    t = e.get("tags", {})
    name = t.get("name:ja") or t.get("name")
    if not name:
        continue
    lat, lon = round(e["lat"], 5), round(e["lon"], 5)
    # **同じ名前の駅が近くに複数あれば 1 つにまとめる**（JR と地下鉄など、事業者ごとに
    # 別の点がある。地図では 1 つの駅として見せる）。約 500m の格子でまとめる
    key = (name, round(lat * 200), round(lon * 200))
    if key not in rows:
        rows[key] = [name, t.get("name:en") or "", lat, lon]
out = sorted(rows.values(), key=lambda r: (r[2], r[3]))
json.dump({"source": "© OpenStreetMap contributors",
           "fields": ["name", "name_en", "lat", "lon"],
           "stations": out},
          open(dst, "w"), ensure_ascii=False, separators=(",", ":"))
print(f"{len(out)} 駅")
PY

ls -la "$OUT"
