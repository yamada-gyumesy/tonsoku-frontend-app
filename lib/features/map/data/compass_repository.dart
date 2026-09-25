import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 端末の向き（方位角。0〜360 度、0 = 北、時計回り）。
///
/// **牛めしレーダー（`gyumeshi-rader-app` の
/// `lib/data/repositories/compass_repository.dart`）を写したもの。**
/// iOS / Android ともにネイティブ実装（EventChannel）から受け取る:
///
/// - iOS: `CLLocationManager` の heading（キャリブレーション済み。
///   `ios/Runner/CompassPlugin.swift`）
/// - Android: `SensorManager` の `TYPE_ROTATION_VECTOR` のセンサーフュージョン
///   （チルト補正・キャリブレーション済み。端末を前後に傾けても方位は変わらない。
///   `CompassStreamHandler.kt`）
///
/// **購読している間だけセンサーを動かす**（`onListen` / `onCancel`）。マップが
/// 進行方向が上のモードの時だけ聞く（`MapPage`）。
class CompassRepository {
  const CompassRepository();

  static const _channel = EventChannel('com.gyumesy.tonsoku/compass');

  Stream<double> headingStream() => _channel.receiveBroadcastStream().map(
    (event) => (event as num).toDouble(),
  );
}

final compassRepositoryProvider = Provider<CompassRepository>(
  (ref) => const CompassRepository(),
);
