import SwiftUI
import SwiftData

@main
struct FinancialTrackerApp: App {
    @StateObject private var dynamicDI = DynamicDIContainer()
    
    init() {
        setupStorage()
        setupNetworkMonitoring()
        setupMigration()
    }
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .background(ShakeDetector())
                .environment(\.di, dynamicDI.currentContainer)
                .environmentObject(dynamicDI)
        }
    }
    
    private func setupStorage() {
        do {
            _ = try SwiftDataManager.shared.modelContainer
            #if DEBUG
            print("✅ Storage systems initialized successfully")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to initialize storage: \(error)")
            #endif
        }
    }
    
    private func setupNetworkMonitoring() {
        _ = NetworkConnectionDetector.shared
        #if DEBUG
        print("📡 Network monitoring started")
        #endif
    }
    
    private func setupMigration() {
        #if DEBUG
        print("🔄 Migration service ready")
        #endif
    }
}
