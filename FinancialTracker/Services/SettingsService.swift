import Foundation
import Combine

enum StorageType: String, CaseIterable {
    case swiftData = "swiftdata"
    case coreData = "coredata"
    
    var displayName: String {
        switch self {
        case .swiftData:
            return "SwiftData"
        case .coreData:
            return "CoreData"
        }
    }
}

protocol SettingsServiceProtocol {
    var storageType: StorageType { get }
    var isDebugEnabled: Bool { get }
    var isAutoSyncEnabled: Bool { get }
    
    var storageTypePublisher: AnyPublisher<StorageType, Never> { get }
    
    func setStorageType(_ type: StorageType)
    func setDebugEnabled(_ enabled: Bool)
    func setAutoSyncEnabled(_ enabled: Bool)
}

final class SettingsService: SettingsServiceProtocol, ObservableObject {
    
    private let userDefaults: UserDefaults
    private let storageTypeSubject = CurrentValueSubject<StorageType, Never>(.swiftData)
    
    private enum Keys {
        static let storageType = "storage_type"
        static let debugEnabled = "debug_enabled"
        static let autoSyncEnabled = "auto_sync_enabled"
        static let version = "version"
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        registerDefaultValues()
        loadCurrentValues()
        startObservingChanges()
    }
    
    var storageType: StorageType {
        return .swiftData
    }
    
    var isDebugEnabled: Bool {
        userDefaults.bool(forKey: Keys.debugEnabled)
    }
    
    var isAutoSyncEnabled: Bool {
        userDefaults.bool(forKey: Keys.autoSyncEnabled)
    }
    
    var storageTypePublisher: AnyPublisher<StorageType, Never> {
        storageTypeSubject.eraseToAnyPublisher()
    }
    
    func setStorageType(_ type: StorageType) {
        userDefaults.set(type.rawValue, forKey: Keys.storageType)
        storageTypeSubject.send(type)
    }
    
    func setDebugEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: Keys.debugEnabled)
    }
    
    func setAutoSyncEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: Keys.autoSyncEnabled)
    }
    
    private func registerDefaultValues() {
        let defaults: [String: Any] = [
            Keys.storageType: StorageType.swiftData.rawValue,
            Keys.debugEnabled: false,
            Keys.autoSyncEnabled: true,
            Keys.version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "1.0"
        ]
        
        userDefaults.register(defaults: defaults)
    }
    
    private func loadCurrentValues() {
        storageTypeSubject.send(storageType)
    }
    
    private func startObservingChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: userDefaults
        )
    }
    
    @objc private func userDefaultsDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.storageTypeSubject.send(self.storageType)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension SettingsService {
    
    func logCurrentSettings() {
        #if DEBUG
        guard isDebugEnabled else { return }
        
        print("📱 Settings Service - Current Configuration:")
        print("   Storage Type: \(storageType.displayName)")
        print("   Debug Enabled: \(isDebugEnabled)")
        print("   Auto Sync Enabled: \(isAutoSyncEnabled)")
        #endif
    }
    
    func exportSettings() -> [String: Any] {
        return [
            "storageType": storageType.rawValue,
            "debugEnabled": isDebugEnabled,
            "autoSyncEnabled": isAutoSyncEnabled
        ]
    }
    
    func importSettings(_ settings: [String: Any]) {
        if let storageTypeRaw = settings["storageType"] as? String,
           let storageType = StorageType(rawValue: storageTypeRaw) {
            setStorageType(storageType)
        }
        
        if let debugEnabled = settings["debugEnabled"] as? Bool {
            setDebugEnabled(debugEnabled)
        }
        
        if let autoSyncEnabled = settings["autoSyncEnabled"] as? Bool {
            setAutoSyncEnabled(autoSyncEnabled)
        }
    }
} 