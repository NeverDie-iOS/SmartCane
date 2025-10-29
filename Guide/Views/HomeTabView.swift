import SwiftUI

struct HomeTabView: View {
    var body: some View {
        ZStack {
            TabView {
                Tab("홈", systemImage: "house") {
                    ObjectScanTestView()
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
