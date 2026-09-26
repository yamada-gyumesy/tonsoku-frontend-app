/**
 * ストア画像の「マップの画面」に敷く地図を、組版で描ける材料に書き出す。
 *
 *     node tool/build_store_map.mts [tonsoku-frontend-web の場所]   # 既定は ../tonsoku-frontend-web
 *
 * ---- なぜ地図を焼くのか ----
 *
 * **ストア画像は実機を撮らない**（`tool/build_store_images.py` の冒頭）。マップも
 * 組版（`store/marketing/screens/map.html`）で描くので、背景の地図は**アプリと同じ地図データ**
 * （`assets/map/japan.pmtiles` / `stations.json`）から線と文字の座標まで計算してここで書き出す。
 *
 * **作りは web の `scripts/generate-map-backdrop.mts` を写した**（web の `/map/` の背景も
 * 同じ目的で同じことをしている）。層の分け方・太さ・文字の大きさはアプリの
 * `lib/features/map/presentation/map_theme.dart` を z14 で評価したもの。
 *
 * **店の印もここで焼く**（web と違う所）。ストア画像は撮った日の配信の写し
 * （`store/fixtures/app/*.json`）で固定する ―― 組み直すたびに印が動くと、
 * 同じ絵を作り直せない。
 *
 * **出力は JS**（`window.MAP_VIEWS`）。headless Chrome は `file://` から JSON を
 * fetch できないので、`<script>` で読める形にする（`screens/_data.js` と同じ）。
 *
 * ---- 依存 ----
 *
 * `pmtiles`（`brew install pmtiles`）と、web のチェックアウトの `node_modules`
 * （`@mapbox/vector-tile` / `pbf`。**このリポジトリには Node の依存を持たない**ので
 * web のものを借りる。web で `yarn install` 済みであること）。
 */
import { execFileSync } from 'node:child_process'
import { readFileSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { gunzipSync } from 'node:zlib'

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const WEB = resolve(process.argv[2] ?? resolve(ROOT, '../tonsoku-frontend-web'))
const { VectorTile } = await import(resolve(WEB, 'node_modules/@mapbox/vector-tile/index.js'))
const { PbfReader: Pbf } = await import(resolve(WEB, 'node_modules/pbf/index.js'))

const PMTILES = resolve(ROOT, 'assets/map/japan.pmtiles')
const STATIONS = resolve(ROOT, 'assets/map/stations.json')
const FIXTURES = resolve(ROOT, 'store/fixtures/app')
const OUT = resolve(ROOT, 'store/marketing/screens/_map.js')

/**
 * 画角。**アプリの初期画面と同じ z14**（1km ≒ 129px）。
 *
 * 大きさは**どの端末の地図の面も覆う大きさ**にする（iPad はスマホの組版を 1.62 倍に
 * 拡げるので、スマホの単位で 637 × 850 ほど要る）。組版は縮めずに原寸で置き、
 * はみ出たぶんを切る。
 */
const ZOOM = 14
const WIDTH = 1000
const HEIGHT = 1200

interface View { name: string, lat: number, lon: number }
const VIEWS: View[] = [
  // 最初の画面（アプリの初期位置。東京駅）
  { name: 'tokyo', lat: 35.6812, lon: 139.7671 },
  // 店を選んだところ（松のや 阿佐ヶ谷南店。ユーザーの見本と同じ店）
  { name: 'asagaya', lat: 35.7028353, lon: 139.6368163 },
]

/** 地図データの最大ズーム（`tool/build_map.sh` の `MAXZOOM`）。ここから引き伸ばして描く */
const DATA_ZOOM = 11
const TILE_PX = 256 * 2 ** (ZOOM - DATA_ZOOM)
const worldPx = 256 * 2 ** ZOOM

function project(lat: number, lon: number): [number, number] {
  const x = ((lon + 180) / 360) * worldPx
  const s = Math.sin((lat * Math.PI) / 180)
  const y = (0.5 - Math.log((1 + s) / (1 - s)) / (4 * Math.PI)) * worldPx
  return [x, y]
}
const r1 = (n: number) => Math.round(n)

function readTile(z: number, x: number, y: number) {
  let buf: Buffer
  try {
    buf = execFileSync('pmtiles', ['tile', '-q', PMTILES, String(z), String(x), String(y)], { maxBuffer: 64 << 20 })
  }
  catch {
    return null
  }
  if (buf.length === 0) return null
  if (buf[0] === 0x1F && buf[1] === 0x8B) buf = gunzipSync(buf)
  return new VectorTile(new Pbf(buf))
}

// ---- 店（配信の写し）----
interface Shop { code: string, lat: number, lon: number, brands: string[], closing_date: string | null, temp_closed: unknown }
interface Menu { campaign_id: string, name: string, shops: string[], sold_out_shops: string[], thumbnail_url: string | null }
const shops = JSON.parse(readFileSync(resolve(FIXTURES, 'shop.json'), 'utf8')) as Shop[]
const menus = JSON.parse(readFileSync(resolve(FIXTURES, 'limited.json'), 'utf8')) as Menu[]
// **選んでいる品は、いま売っている店がいちばん多い品**（画面の品のチップの先頭）
const menu = [...menus].sort((a, b) => b.shops.length - a.shops.length)[0]
const soldOut = new Set(menu.sold_out_shops)
const limitedCodes = new Set([...menu.shops, ...menu.sold_out_shops])

/** 併設の区別（アプリの `ShopDot.colorsFor`）。松屋併設を先に見る */
const dotKind = (s: Shop) => s.brands.includes('matsuya') ? 'matsuya' : s.brands.includes('mycurry') ? 'mycurry' : 'standalone'

function build(view: View) {
  const [cx, cy] = project(view.lat, view.lon)
  const left = cx - WIDTH / 2
  const top = cy - HEIGHT / 2
  const inView = (x: number, y: number) => x >= 0 && x <= WIDTH && y >= 0 && y <= HEIGHT

  const paths: Record<string, string[]> = {
    earth: [], water: [], boundaryLocality: [], boundaryRegion: [], majorRoad: [], highway: [], rail: [],
  }
  const places: { x: number, y: number, size: number, ja: string }[] = []

  for (let tx = Math.floor(left / TILE_PX); tx <= Math.floor((left + WIDTH) / TILE_PX); tx++) {
    for (let ty = Math.floor(top / TILE_PX); ty <= Math.floor((top + HEIGHT) / TILE_PX); ty++) {
      const tile = readTile(DATA_ZOOM, tx, ty)
      if (!tile) continue
      for (const [name, layer] of Object.entries(tile.layers) as [string, any][]) {
        const scale = TILE_PX / layer.extent
        const ox = tx * TILE_PX - left
        const oy = ty * TILE_PX - top
        for (let i = 0; i < layer.length; i++) {
          const f = layer.feature(i)
          const p = f.properties
          const rings = f.loadGeometry().map((ring: { x: number, y: number }[]) =>
            ring.map(pt => [ox + pt.x * scale, oy + pt.y * scale] as const))
          if (name === 'places') {
            // 地名はアプリの `places-city`（14px）と `places-town`（12px）だけ
            if (p.kind !== 'locality') continue
            const size = p.kind_detail === 'city' ? 14 : ['town', 'village'].includes(String(p.kind_detail)) ? 12 : 0
            if (!size) continue
            const [x, y] = rings[0][0]
            if (!inView(x, y)) continue
            places.push({ x: r1(x), y: r1(y), size, ja: String(p['name:ja'] ?? p.name) })
            continue
          }
          const key = name === 'earth' ? 'earth'
            : name === 'water' ? 'water'
              : name === 'boundaries' ? (p.kind === 'region' ? 'boundaryRegion' : p.kind === 'country' ? null : 'boundaryLocality')
                : name === 'roads' ? (p.kind === 'rail' ? 'rail' : p.kind === 'highway' ? 'highway' : p.kind === 'major_road' ? 'majorRoad' : null)
                  : null
          if (!key) continue
          const closed = f.type === 3
          for (const ring of rings) {
            if (ring.length < 2) continue
            paths[key].push(`M${ring.map(([x, y]: readonly [number, number]) => `${r1(x)} ${r1(y)}`).join('L')}${closed ? 'Z' : ''}`)
          }
        }
      }
    }
  }

  // 重なった文字を落とす（アプリは重なる地名を出さない）。大きい地名から置く
  type Box = [number, number, number, number]
  const placed: Box[] = []
  const fits = (b: Box) => {
    if (placed.some(o => b[0] < o[2] && b[2] > o[0] && b[1] < o[3] && b[3] > o[1])) return false
    placed.push(b)
    return true
  }
  places.sort((a, b) => b.size - a.size)
  const keptPlaces = places.filter((p) => {
    const w = [...p.ja].length * p.size
    return fits([p.x - w / 2 - 2, p.y - p.size / 2 - 2, p.x + w / 2 + 2, p.y + p.size / 2 + 2])
  })

  // 駅（アプリの `StationsLayer`。z13 以上で出す）。列は `fields` から引く
  const src = JSON.parse(readFileSync(STATIONS, 'utf8')) as { fields: string[], stations: unknown[][] }
  const col = (k: string) => src.fields.indexOf(k)
  const [iJa, iLat, iLon] = [col('name'), col('lat'), col('lon')]
  const stations = src.stations
    .map((row) => {
      const [x, y] = project(Number(row[iLat]), Number(row[iLon]))
      return { x: r1(x - left), y: r1(y - top), ja: String(row[iJa]) }
    })
    .filter(s => inView(s.x, s.y))
    .filter((s, i, all) => !all.slice(0, i).some(o => o.ja === s.ja && Math.hypot(o.x - s.x, o.y - s.y) < 200))
    .filter(s => fits([s.x - 4, s.y - 7, s.x + 6 + [...s.ja].length * 10, s.y + 7]))

  // 店。**画面の外の店舗限定も持つ**（吹き出しの数に使う）
  const dots: { x: number, y: number, kind: string }[] = []
  const limited: { x: number, y: number, kind: 'selling' | 'soldOut' }[] = []
  for (const s of shops) {
    if (s.closing_date) continue
    const [x, y] = project(s.lat, s.lon)
    const pt = { x: r1(x - left), y: r1(y - top) }
    if (limitedCodes.has(s.code)) limited.push({ ...pt, kind: soldOut.has(s.code) ? 'soldOut' : 'selling' })
    else if (inView(pt.x, pt.y)) dots.push({ ...pt, kind: dotKind(s) })
  }

  return {
    width: WIDTH,
    height: HEIGHT,
    paths: Object.fromEntries(Object.entries(paths).map(([k, v]) => [k, v.join('')])),
    places: keptPlaces,
    stations,
    dots,
    limited,
  }
}

const out: Record<string, unknown> = {}
for (const v of VIEWS) out[v.name] = build(v)
const menuOut = {
  name: menu.name,
  shops: menu.shops.length + menu.sold_out_shops.length,
  selling: menu.shops.length,
  soldOut: menu.sold_out_shops.length,
  ended: 0,
}
writeFileSync(OUT, `// **生成物。手で直さない**（\`node tool/build_store_map.mts\`）\nwindow.MAP_VIEWS = ${JSON.stringify(out)};\nwindow.MAP_MENU = ${JSON.stringify(menuOut)};\n`)
console.info(`[map] ${Math.round(readFileSync(OUT).length / 1024)}KB → ${OUT}`)
