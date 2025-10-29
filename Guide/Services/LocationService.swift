import SwiftUI
import CoreLocation
import MapKit
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var text = ""
    @Published var authorization: CLAuthorizationStatus
    @Published var lastLocation: CLLocation?
    @Published var cameraPosition: MapCameraPosition = .automatic
    
    override init() {
        self.authorization = .notDetermined
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestWhenInUse() {
        // 권한 요청
        manager.requestWhenInUseAuthorization()
    }
    
    func start() {
        // 권한 허용 시 위치 업데이트 시작
        print("start()")
        manager.startUpdatingLocation()
    }
    
    // 위치 업데이트 콜백
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //        guard let loc = locations.last else { return }
        //        lastLocation = loc
        //
        //        // 사용자 위치로 카메라 이동
        //        let coord = loc.coordinate
        //        let region = MKCoordinateRegion(center: coord,
        //                                        span: .init(latitudeDelta: 0.01, longitudeDelta: 0.01))
        //        DispatchQueue.main.async {
        //            self.cameraPosition = .region(region)
        //        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        text = "진입" // 디버그 로그
        scheduleLocalNotification(title: "출발 정류장 도착",
                                  body: "정류장 반경 10m에 진입했습니다.")
    }
    
    private func scheduleLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        // 즉시 발송
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func startMonitoringStop(center: CLLocationCoordinate2D, radius: CLLocationDistance) {
        print("startMonitoringStop")
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("Region monitoring not available")
            return
        }
        let region = CLCircularRegion(center: center, radius: radius, identifier: "stop-geo")
        region.notifyOnEntry = true
        region.notifyOnExit = false
        manager.startMonitoring(for: region)
        print("Monitoring regions:", manager.monitoredRegions.count)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didDetermineState state: CLRegionState,
                         for region: CLRegion) {
        switch state {
        case .inside:
            print("🟡 [STATE] INSIDE → 영역 안: ", region.identifier)
            text = "🟡 [STATE] INSIDE → 영역 안"
        case .outside:
            print("🟠 [STATE] OUTSIDE → 영역 밖: ", region.identifier)
            text = "🟠 [STATE] OUTSIDE → 영역 밖"
        case .unknown:
            print("⚪️ [STATE] UNKNOWN → 일시적으로 판단 불가:", region.identifier)
            text = "⚪️ [STATE] UNKNOWN → 일시적으로 판단 불가"
        @unknown default:
            print("⚪️ [STATE] UNKNOWN(default):", region.identifier)
        }

        if let circ = region as? CLCircularRegion, let here = manager.location {
            let d = here.distance(from: CLLocation(latitude: circ.center.latitude,
                                                   longitude: circ.center.longitude))
            print(String(format: "    center=(%.6f, %.6f) r=%.1fm | current=(%.6f, %.6f) dist=%.1fm",
                         circ.center.latitude, circ.center.longitude, circ.radius,
                         here.coordinate.latitude, here.coordinate.longitude, d))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error)
    }
}

