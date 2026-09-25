import Flutter
import CoreLocation

class CompassStreamHandler: NSObject, FlutterStreamHandler, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.headingFilter = 1
        locationManager?.startUpdatingHeading()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        locationManager?.stopUpdatingHeading()
        locationManager?.delegate = nil
        locationManager = nil
        eventSink = nil
        return nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            eventSink?(newHeading.magneticHeading)
        }
    }
}
