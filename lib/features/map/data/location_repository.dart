import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 現在地。**牛めしレーダー（`gyumeshi-rader-app` の
/// `lib/data/repositories/location_repository.dart`）の許可の流れを写したもの。**
///
/// レーダーとの違い:
///
/// - 許可を求めるのは**マップを開いた時**（ユーザーの判断。起動時ではない）。
///   開いたらまず現在地へ寄せる
/// - 位置を追い続けない（`positionStream` を持たない）。ボタンを押した時に 1 回だけ取る
class LocationRepository {
  const LocationRepository();

  /// 許可を求めてから現在地を取る。**取れなければ null**（位置情報が切られている・
  /// 許可されなかった・時間内に測れなかった）。
  Future<Position?> current() async {
    if (!await _requestPermission()) return null;
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
