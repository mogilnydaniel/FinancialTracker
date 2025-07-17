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
    
    private func setupStorageTypeObservation() {
        settingsService.storageTypePublisher
            .dropFirst()
            .sink { [weak self] newStorageType in
                self?.updateContainer(for: newStorageType)
            }
            .store(in: &cancellables)
    }
    
    private func updateContainer(for storageType: StorageType) {
        currentContainer = Self.createContainer(for: storageType)
        objectWillChange.send()
    }
    
    private static func createContainer(for storageType: StorageType) -> DIContainer {
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        
        return DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        )
    }
    
    private static func createSwiftDataContainer(client: NetworkClient) -> DIContainer {
        let manager = SwiftDataManager.shared
        
        do {
            let transactionsPersistence = try manager.createTransactionsPersistence()
            let bankAccountsPersistence = try manager.createBankAccountsPersistence()
            let categoriesPersistence = try manager.createCategoriesPersistence()
            let backup = try manager.createBackupPersistence()
            
            let backupSyncService = BackupSyncService(
                backup: backup,
                networkClient: client,
                transactionsPersistence: transactionsPersistence,
                bankAccountsPersistence: bankAccountsPersistence
            )
            
            return DIContainer(
                categoriesService: HybridCategoriesService(
                    persistence: categoriesPersistence,
                    networkClient: client
                ),
                bankAccountsService: HybridBankAccountsService(
                    persistence: bankAccountsPersistence,
                    backup: backup,
                    networkClient: client,
                    syncService: backupSyncService
                ),
                transactionsService: HybridTransactionsService(
                    persistence: transactionsPersistence,
                    backup: backup,
                    networkClient: client,
                    syncService: backupSyncService
                )
            )
        } catch {
            fatalError("Failed to create SwiftData DIContainer: \(error)")
        }
    }
    
    private static func createCoreDataContainer(client: NetworkClient) -> DIContainer {
        let manager = CoreDataManager.shared
        
        guard manager.isCoreDataAvailable else {
            #if DEBUG
            print("⚠️  CoreData not available, falling back to SwiftData")
            #endif
            return createSwiftDataContainer(client: client)
        }
        
        let transactionsPersistence = manager.createTransactionsPersistence()
        let bankAccountsPersistence = manager.createBankAccountsPersistence()
        let categoriesPersistence = manager.createCategoriesPersistence()
        let backup = manager.createBackupPersistence()
        
        let backupSyncService = BackupSyncService(
            backup: backup,
            networkClient: client,
            transactionsPersistence: transactionsPersistence,
            bankAccountsPersistence: bankAccountsPersistence
        )
        
        return DIContainer(
            categoriesService: HybridCategoriesService(
                persistence: categoriesPersistence,
                networkClient: client
            ),
            bankAccountsService: HybridBankAccountsService(
                persistence: bankAccountsPersistence,
                backup: backup,
                networkClient: client,
                syncService: backupSyncService
            ),
            transactionsService: HybridTransactionsService(
                persistence: transactionsPersistence,
                backup: backup,
                networkClient: client,
                syncService: backupSyncService
            )
        )
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
