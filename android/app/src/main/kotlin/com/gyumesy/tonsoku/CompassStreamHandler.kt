package com.gyumesy.tonsoku

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel

/**
 * Android ネイティブのコンパス。
 * TYPE_ROTATION_VECTOR（加速度計＋磁力計＋ジャイロのセンサーフュージョン）から
 * azimuth（真方位ではなく磁方位。0=北, 時計回り）を算出して配信する。
 *
 * ROTATION_VECTOR は端末側でチルト補正・キャリブレーションが行われるため、
 * 端末を前後に傾けても（ピッチ）方位は変わらず、画面の水平面に対する向き（ヨー）
 * のみで方位が決まる。自前の加速度計＋磁力計合成に比べて安定・正確。
 */
class CompassStreamHandler(private val context: Context) :
    EventChannel.StreamHandler, SensorEventListener {

    private var sensorManager: SensorManager? = null
    private var rotationSensor: Sensor? = null
    private var eventSink: EventChannel.EventSink? = null

    private val rotationMatrix = FloatArray(9)
    private val remappedMatrix = FloatArray(9)
    private val orientation = FloatArray(3)

    // 角度EMA（周回考慮）＋適応スムージング。
    // 微小変化（＝センサーノイズ）は強く抑え、大きな変化（＝意図的な回転）は追従する。
    private var smoothed: Double? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        smoothed = null
        val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensorManager = sm
        val sensor = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        rotationSensor = sensor
        if (sensor != null) {
            sm.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
        }
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(this)
        sensorManager = null
        rotationSensor = null
        eventSink = null
        smoothed = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (event.sensor.type != Sensor.TYPE_ROTATION_VECTOR) return

        SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
        // アプリは縦持ち(ポートレート)固定。端末を立てて画面を見る姿勢でも方位が
        // 正しく・持ち方で90/180度ズレないよう、座標系をリマップしてから方位を取る。
        // AXIS_X, AXIS_Z は「縦持ちで端末が向いている方向（画面の裏側＝視線方向）」の
        // 方位を返す定石。これで getOrientation そのままのジンバルロック/基準ズレを回避。
        SensorManager.remapCoordinateSystem(
            rotationMatrix,
            SensorManager.AXIS_X,
            SensorManager.AXIS_Z,
            remappedMatrix,
        )
        // orientation[0] = azimuth（ヨー・チルト補正済み）, [1] = pitch, [2] = roll
        SensorManager.getOrientation(remappedMatrix, orientation)
        var azimuth = Math.toDegrees(orientation[0].toDouble())
        if (azimuth < 0) azimuth += 360.0

        val prev = smoothed
        if (prev == null) {
            smoothed = azimuth
        } else {
            var diff = azimuth - prev
            if (diff > 180) diff -= 360
            if (diff < -180) diff += 360
            // 変化量に応じてスムージング係数を可変にする（ノイズ抑制＋追従の両立）
            val absDiff = Math.abs(diff)
            val alpha = when {
                absDiff < 1.5 -> 0.04
                absDiff < 6.0 -> 0.12
                absDiff < 30.0 -> 0.30
                else -> 0.6
            }
            var next = (prev + alpha * diff) % 360
            if (next < 0) next += 360
            smoothed = next
        }
        eventSink?.success(smoothed)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
