import SwiftUI

@main
struct FinancialTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .background(ShakeDetector())
                .environment(\.di, .production)
        }
    }
}
