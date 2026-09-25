import 'dart:io' show gzip;
import 'dart:typed_data';

/// PMTiles（v3）の読み手。**同梱の背景地図 `assets/map/japan.pmtiles` を読むためだけ**の
/// 最小限の実装。
///
/// ## なぜ自前で持つか
///
/// **公開のパッケージが今の依存と両立しない**（2026-09-25 に `flutter pub add` で確認）:
///
/// - `vector_map_tiles_pmtiles`（1.5.0 が最新）は `vector_map_tiles ^8`（＝
///   `flutter_map ^7`）にしか対応しておらず、今の `flutter_map 8` と組めない
/// - その中身の `pmtiles`（2.x）は `protobuf ^6` を要求し、`vector_tile_renderer`
///   が要る `vector_tile`（`protobuf ^3`）とぶつかって解決できない
///
/// 読むのは「ヘッダー → ディレクトリ → タイル」だけで、書式は公開されている
/// （https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md ）。
/// 百数十行で済むので、依存の縛りを抱えるより持つほうを採った。
///
/// ## 読み方
///
/// **ファイルを丸ごとメモリに置いて読む**（[PmTiles.new] に全体のバイト列を渡す）。
/// 同梱のアセットはファイルのパスを持たない（Android は APK の中）ので、
/// 読み出すには一度 `rootBundle.load` するしかない。**端末へ書き出して
/// ランダムアクセスで読む形は採らない** ―― アプリ本体に 30MB、書き出した先に
/// もう 30MB と、利用者の端末の容量を二重に使うことになる（メモリの 30MB は
/// マップを開いている間だけ）。
class PmTiles {
  PmTiles(this._bytes) : header = PmTilesHeader.parse(_bytes) {
    if (header.internalCompression > 2 || header.tileCompression > 2) {
      throw const FormatException('PMTiles: gzip 以外の圧縮は読めない');
    }
  }

  final Uint8List _bytes;
  final PmTilesHeader header;

  /// 地図の中身の指紋（作り直したら変わる値）。**全体の大きさと、ヘッダ・
  /// ルートディレクトリのバイト**から作る（30MB 全部は読まない。ルートには
  /// 全タイルの位置が畳み込まれているので、中身が変われば変わる）。
  String get fingerprint {
    final root = Uint8List.sublistView(
      _bytes,
      0,
      header.rootDirOffset + header.rootDirLength,
    );
    return '${_bytes.length.toRadixString(16)}-${fnv1a(root)}';
  }

  /// 読み解いたディレクトリ（位置 → 項目）。**葉のディレクトリは数百あり、
  /// 同じものを何度も引く**ので、一度解いたものは持っておく。
  final _directories = <int, List<PmTilesEntry>>{};

  /// タイル 1 枚（MVT。**解凍済み**）。**無ければ null**（海だけの区画は
  /// 書き出されていない）。
  Uint8List? tile(int z, int x, int y) {
    final id = zxyToTileId(z, x, y);
    var dirOffset = header.rootDirOffset;
    var dirLength = header.rootDirLength;
    // 仕様上ディレクトリの深さは 3 段まで（根 → 葉 → 葉）
    for (var depth = 0; depth < 4; depth++) {
      final entries = _directory(dirOffset, dirLength);
      final entry = findEntry(entries, id);
      if (entry == null) return null;
      if (entry.runLength > 0) {
        final start = header.tileDataOffset + entry.offset;
        return _decompress(
          Uint8List.sublistView(_bytes, start, start + entry.length),
          header.tileCompression,
        );
      }
      // runLength が 0 は葉のディレクトリを指す
      dirOffset = header.leafDirOffset + entry.offset;
      dirLength = entry.length;
    }
    return null;
  }

  List<PmTilesEntry> _directory(int offset, int length) =>
      _directories.putIfAbsent(
        offset,
        () => decodeDirectory(
          _decompress(
            Uint8List.sublistView(_bytes, offset, offset + length),
            header.internalCompression,
          ),
        ),
      );

  static Uint8List _decompress(Uint8List data, int compression) =>
      // 0: 不明 / 1: 無圧縮 / 2: gzip
      compression == 2 ? Uint8List.fromList(gzip.decode(data)) : data;
}

/// 先頭 127 バイトのヘッダー。
class PmTilesHeader {
  const PmTilesHeader({
    required this.rootDirOffset,
    required this.rootDirLength,
    required this.leafDirOffset,
    required this.tileDataOffset,
    required this.internalCompression,
    required this.tileCompression,
    required this.minZoom,
    required this.maxZoom,
  });

  factory PmTilesHeader.parse(Uint8List bytes) {
    if (bytes.length < 127 ||
        String.fromCharCodes(bytes.sublist(0, 7)) != 'PMTiles' ||
        bytes[7] != 3) {
      throw const FormatException('PMTiles v3 ではない');
    }
    final data = ByteData.sublistView(bytes);
    int u64(int at) => data.getUint64(at, Endian.little);
    return PmTilesHeader(
      rootDirOffset: u64(8),
      rootDirLength: u64(16),
      leafDirOffset: u64(40),
      tileDataOffset: u64(56),
      internalCompression: bytes[97],
      tileCompression: bytes[98],
      minZoom: bytes[100],
      maxZoom: bytes[101],
    );
  }

  final int rootDirOffset;
  final int rootDirLength;
  final int leafDirOffset;
  final int tileDataOffset;
  final int internalCompression;
  final int tileCompression;
  final int minZoom;
  final int maxZoom;
}

/// ディレクトリの 1 項目。[runLength] が 0 なら葉のディレクトリを指す。
class PmTilesEntry {
  const PmTilesEntry(this.tileId, this.offset, this.length, this.runLength);

  final int tileId;
  final int offset;
  final int length;
  final int runLength;
}

/// 解凍済みのディレクトリを読む。**列ごとに並んでいる**（件数 → ID の差分 →
/// 連続数 → 長さ → 位置）。位置は「0 なら直前の項目の続き、それ以外は値 − 1」。
List<PmTilesEntry> decodeDirectory(Uint8List data) {
  var pos = 0;
  int varint() {
    var result = 0;
    var shift = 0;
    while (true) {
      final b = data[pos++];
      result |= (b & 0x7f) << shift;
      if (b < 0x80) return result;
      shift += 7;
    }
  }

  final n = varint();
  final ids = List<int>.filled(n, 0);
  final runs = List<int>.filled(n, 0);
  final lengths = List<int>.filled(n, 0);
  final offsets = List<int>.filled(n, 0);
  var last = 0;
  for (var i = 0; i < n; i++) {
    last += varint();
    ids[i] = last;
  }
  for (var i = 0; i < n; i++) {
    runs[i] = varint();
  }
  for (var i = 0; i < n; i++) {
    lengths[i] = varint();
  }
  for (var i = 0; i < n; i++) {
    final v = varint();
    offsets[i] = (v == 0 && i > 0) ? offsets[i - 1] + lengths[i - 1] : v - 1;
  }
  return [
    for (var i = 0; i < n; i++)
      PmTilesEntry(ids[i], offsets[i], lengths[i], runs[i]),
  ];
}

/// [id] を含む項目を探す（ID が [id] 以下で最大の項目）。**葉を指す項目は
/// 範囲を持たない**（その先に降りて探す）ので、そのまま返す。
PmTilesEntry? findEntry(List<PmTilesEntry> entries, int id) {
  var lo = 0;
  var hi = entries.length - 1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    final c = entries[mid].tileId;
    if (c < id) {
      lo = mid + 1;
    } else if (c > id) {
      hi = mid - 1;
    } else {
      return entries[mid];
    }
  }
  if (hi < 0) return null;
  final entry = entries[hi];
  if (entry.runLength == 0) return entry;
  return id - entry.tileId < entry.runLength ? entry : null;
}

/// z/x/y をタイル ID にする（ズームごとの通し番号 ＋ ヒルベルト曲線上の位置）。
/// 仕様の参照実装（`zxyToTileId`）と同じ計算。
int zxyToTileId(int z, int x, int y) {
  if (z > 26) throw ArgumentError('z は 26 まで: $z');
  final n = 1 << z;
  if (x < 0 || y < 0 || x >= n || y >= n) {
    throw ArgumentError('範囲外のタイル: $z/$x/$y');
  }
  // 手前のズームのタイル数の和（(4^z − 1) / 3）
  final acc = ((1 << (2 * z)) - 1) ~/ 3;
  var tx = x;
  var ty = y;
  var d = 0;
  for (var s = n >> 1; s > 0; s >>= 1) {
    final rx = (tx & s) > 0 ? 1 : 0;
    final ry = (ty & s) > 0 ? 1 : 0;
    d += s * s * ((3 * rx) ^ ry);
    if (ry == 0) {
      if (rx == 1) {
        tx = n - 1 - tx;
        ty = n - 1 - ty;
      }
      final t = tx;
      tx = ty;
      ty = t;
    }
  }
  return acc + d;
}

/// FNV-1a（32 ビット）を 16 進で。**実行ごと・版ごとに変わらない**ハッシュが要る
/// ところで使う（`String.hashCode` / `Object.hash` は実行ごとに変わってよい決まり）。
String fnv1a(List<int> bytes) {
  var h = 0x811c9dc5;
  for (final b in bytes) {
    h ^= b & 0xff;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}
