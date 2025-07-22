import Foundation
import SwiftUI
import Combine

@MainActor
final class DynamicDIContainer: ObservableObject {
    
    @Published private(set) var currentContainer: DIContainer
    
    private let settingsService: SettingsService
    private let migrationService: AutoMigrationService
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.settingsService = SettingsService()
        
        self.currentContainer = Self.createContainer(for: settingsService.storageType)
        
        let dataMigrationService = DataMigrationService()
        self.migrationService = AutoMigrationService(
            settingsService: settingsService,
            migrationService: dataMigrationService
        )
        
        setupStorageTypeObservation()
    }
    
    private func updateContainer(for storageType: StorageType) {
        #if DEBUG
        print("Switching to \(storageType.displayName) storage mode")
        #endif
        
        currentContainer = Self.createContainer(for: storageType)
        
        #if DEBUG
        print("Successfully switched to \(storageType.displayName) mode")
        #endif
    }
    
    private static func createContainer(for storageType: StorageType) -> DIContainer {
        let client = NetworkClient(token: DIContainer.apiToken)
        
        switch storageType {
        case .swiftData:
            return createHybridContainer(storageType: .swiftData, networkClient: client)
        case .coreData:
            return createHybridContainer(storageType: .coreData, networkClient: client)
        }
    }
    
    private static func createHybridContainer(storageType: StorageType, networkClient: NetworkClient) -> DIContainer {
        #if DEBUG
        print("Creating Hybrid container with \(storageType.displayName)")
        #endif

        let (transactionsPersistence, categoriesPersistence, bankAccountsPersistence, backupPersistence) = createPersistenceLayers(for: storageType)

        let backupSyncService = BackupSyncService(
            backup: backupPersistence,
            networkClient: networkClient,
            transactionsPersistence: transactionsPersistence,
            bankAccountsPersistence: bankAccountsPersistence
        )

        let categoriesService = HybridCategoriesService(
            persistence: categoriesPersistence,
            networkClient: networkClient
        )
        
        let bankAccountsService = HybridBankAccountsService(
            persistence: bankAccountsPersistence,
            backup: backupPersistence,
            networkClient: networkClient,
            syncService: backupSyncService
        )
        
        let transactionsService = HybridTransactionsService(
            persistence: transactionsPersistence,
            backup: backupPersistence,
            networkClient: networkClient,
            syncService: backupSyncService
        )
        
        #if DEBUG
        print("Created all Hybrid services for \(storageType.displayName)")
        #endif
        
        return DIContainer(
            categoriesService: categoriesService,
            bankAccountsService: bankAccountsService,
            transactionsService: transactionsService
        )
    }
    
    private static func createPersistenceLayers(for storageType: StorageType) -> (
        TransactionsPersistenceProtocol,
        CategoriesPersistenceProtocol,
        BankAccountsPersistenceProtocol,
        any BackupProtocol
    ) {
        switch storageType {
        case .swiftData:
            do {
                let manager = SwiftDataManager.shared
                return (
                    try manager.createTransactionsPersistence(),
                    try manager.createCategoriesPersistence(),
                    try manager.createBankAccountsPersistence(),
                    try manager.createBackupPersistence()
                )
            } catch {
                #if DEBUG
                print("Failed to create SwiftData persistence: \(error)")
                print("Falling back to CoreData")
                #endif
                let manager = CoreDataManager.shared
                return (
                    manager.createTransactionsPersistence(),
                    manager.createCategoriesPersistence(),
                    manager.createBankAccountsPersistence(),
                    manager.createBackupPersistence()
                )
            }
            
        case .coreData:
            let manager = CoreDataManager.shared
            return (
                manager.createTransactionsPersistence(),
                manager.createCategoriesPersistence(),
                manager.createBankAccountsPersistence(),
                manager.createBackupPersistence()
            )
        }
    }
}

private struct DynamicDIContainerKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: DynamicDIContainer = DynamicDIContainer()
}

extension EnvironmentValues {
    var dynamicDI: DynamicDIContainer {
        get { self[DynamicDIContainerKey.self] }
        set { self[DynamicDIContainerKey.self] = newValue }
    }
} 
