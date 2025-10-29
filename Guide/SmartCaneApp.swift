import SwiftUI

@main
struct GuideApp: App {
    @StateObject private var lm = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            HomeTabView()
                .environmentObject(lm)
                .task {
                    // 앱 시작 시 권한 요청
                    lm.requestWhenInUse()
                    _ = try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge])
                }
        }
    }
}

