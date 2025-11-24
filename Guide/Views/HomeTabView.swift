import SwiftUI

struct HomeTabView: View {
    var body: some View {
        ZStack {
            TabView {
                Tab("AI 사물인식", systemImage: "camera.viewfinder") {
                    ObjectScanTestView()
                }
                Tab("출입구 인식", systemImage: "door.left.hand.open") {
                    DoorDetectionView()
                }
                Tab("지도", systemImage: "map") {
                    MapView()
                }
            }
            
            VStack {
                Spacer()
                
                Rectangle()
                    .fill(.gray)
                    .frame(height: 1)
                    .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    HomeTabView()
}
