import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 現在地。**牛めしレーダー（`gyumeshi-rader-app` の
/// `lib/data/repositories/location_repository.dart`）の許可の流れを写したもの。**
///
/// レーダーとの違い:
///
/// - **開いただけでは許可を求めない。** レーダーは現在地が画面の主役なので起動時に
///   聞くが、とん速のマップは店を見るのが主で、現在地は「現在地」ボタンを押した
///   人だけが使う。**既に許可されていれば**開いた時に現在地へ寄せる
///   （[currentIfPermitted]）
/// - 位置を追い続けない（`positionStream` を持たない）。ボタンを押した時に 1 回だけ取る
class LocationRepository {
  const LocationRepository();

  /// 許可を求めてから現在地を取る。**取れなければ null**（位置情報が切られている・
  /// 許可されなかった・時間内に測れなかった）。
  Future<Position?> current() async {
    if (!await _requestPermission()) return null;
    return _position();
  }

  /// **許可を求めずに**現在地を取る。既に許可されている時だけ位置が返る。
  Future<Position?> currentIfPermitted() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return null;
    }
    return _position();
  }

  Future<bool> _requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<Position?> _position() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } on Object {
      // 時間切れ・測位の失敗。**画面は前の位置のまま**（落とさない）
      return null;
    }
  }
}

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => const LocationRepository(),
);
