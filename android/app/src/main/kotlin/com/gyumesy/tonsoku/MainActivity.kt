package com.gyumesy.tonsoku

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // マップの北上／進行方向の切り替えに使う方位（牛めしレーダーの MainActivity を写した）
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.gyumesy.tonsoku/compass",
        ).setStreamHandler(CompassStreamHandler(applicationContext))
    }
}
