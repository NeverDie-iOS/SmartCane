import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var lm: LocationManager
    private let stopCoord = CLLocationCoordinate2D(latitude: 35.179039, longitude: 126.917531)
    
    var body: some View {
        ZStack {
            Map(position: $lm.cameraPosition) {
                UserAnnotation()
                Marker("출발 정류장", systemImage: "bus.fill", coordinate: stopCoord)
                    .tint(.red)
                MapCircle(center: stopCoord, radius: 5)
                    .foregroundStyle(.blue.opacity(0.2))
                    .stroke(.blue, lineWidth: 2)
            }
            .mapControls {
                MapUserLocationButton()      // 위치 이동 버튼
                MapCompass()                 // 나침반
            }
            .onAppear {
                lm.start()
                lm.startMonitoringStop(center: stopCoord, radius: 5)   // 지오펜싱 등록
                print("지오펜싱 등록되었습니다.")
            }
            
            Text(lm.text)
                .font(.system(size: 30, weight: .bold))
        }
    }
}
