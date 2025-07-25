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
                .environment(\.locale, Locale(identifier: "ru_RU"))
        }
    }
    
    private func setupStorage() {
        #if DEBUG
        let startTime = Date()
        print("Starting storage initialization...")
        #endif
        
        do {
            _ = try SwiftDataManager.shared.modelContainer
            #if DEBUG
            let elapsed = Date().timeIntervalSince(startTime)
            print("Storage systems initialized successfully in \(String(format: "%.2f", elapsed))s")
            #endif
        } catch {
            #if DEBUG
            print("Failed to initialize storage: \(error)")
            #endif
        }
    }
    
    private func setupNetworkMonitoring() {
        _ = NetworkConnectionDetector.shared
        #if DEBUG
        print("Network monitoring started")
        #endif
    }
    
    private func setupMigration() {
        #if DEBUG
        print("Migration service ready")
        #endif
    }
}
