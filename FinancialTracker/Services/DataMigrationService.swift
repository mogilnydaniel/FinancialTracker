import Foundation

protocol DataMigrationProtocol {
    func migrateFromSwiftDataToCoreData() async throws
    func migrateFromCoreDataToSwiftData() async throws
    func clearSwiftDataStorage() async throws
    func clearCoreDataStorage() async throws
    func getMigrationStats() async throws -> MigrationStats
}

struct MigrationStats {
    let swiftDataTransactions: Int
    let swiftDataAccounts: Int
    let swiftDataCategories: Int
    let swiftDataBackups: Int
    
    let coreDataTransactions: Int
    let coreDataAccounts: Int
    let coreDataCategories: Int
    let coreDataBackups: Int
    
    var hasSwiftDataData: Bool {
        swiftDataTransactions > 0 || swiftDataAccounts > 0 || swiftDataCategories > 0 || swiftDataBackups > 0
    }
    
    var hasCoreDataData: Bool {
        coreDataTransactions > 0 || coreDataAccounts > 0 || coreDataCategories > 0 || coreDataBackups > 0
    }
}

final class DataMigrationService: DataMigrationProtocol {
    
    private let swiftDataManager: SwiftDataManager
    private let coreDataManager: CoreDataManager
    
    init(
        swiftDataManager: SwiftDataManager = .shared,
        coreDataManager: CoreDataManager = .shared
    ) {
        self.swiftDataManager = swiftDataManager
        self.coreDataManager = coreDataManager
    }
    
    func migrateFromSwiftDataToCoreData() async throws {
        #if DEBUG
        print("Starting migration: SwiftData → CoreData")
        #endif
        
        let swiftDataTransactions = try swiftDataManager.createTransactionsPersistence()
        let swiftDataAccounts = try swiftDataManager.createBankAccountsPersistence()
        let swiftDataCategories = try swiftDataManager.createCategoriesPersistence()
        let swiftDataBackups = try swiftDataManager.createBackupPersistence()
        
        let coreDataTransactions = coreDataManager.createTransactionsPersistence()
        let coreDataAccounts = coreDataManager.createBankAccountsPersistence()
        let coreDataCategories = coreDataManager.createCategoriesPersistence()
        let coreDataBackups = coreDataManager.createBackupPersistence()
        
        try await coreDataTransactions.clearAllTransactions()
        try await coreDataAccounts.clearAllBankAccounts()
        try await coreDataCategories.deleteAllCategories()
        try await coreDataBackups.clearAllBackups()
        
        let transactions = try await swiftDataTransactions.getAllTransactions()
        let account = try await swiftDataAccounts.getBankAccount()
        let categories = try await swiftDataCategories.getCategories()
        let backups = try await swiftDataBackups.getAllBackupItems()
        
        print("📊 Migrating \(transactions.count) transactions")
        try await coreDataTransactions.saveTransactions(transactions)
        
        if let account = account {
            print("📊 Migrating 1 account")
            _ = try await coreDataAccounts.saveBankAccount(account)
        }
        
        print("📊 Migrating \(categories.count) categories")
        try await coreDataCategories.saveCategories(categories)
        
        print("📊 Migrating \(backups.count) backup items")
        for backup in backups {
            try await coreDataBackups.createBackup(backup as! BackupItem<Transaction>)
        }
        
        print("✅ Migration completed: SwiftData → CoreData")
    }
    
    func migrateFromCoreDataToSwiftData() async throws {
        print("🔄 Starting migration: CoreData → SwiftData")
        
        let swiftDataTransactions = try swiftDataManager.createTransactionsPersistence()
        let swiftDataAccounts = try swiftDataManager.createBankAccountsPersistence()
        let swiftDataCategories = try swiftDataManager.createCategoriesPersistence()
        let swiftDataBackups = try swiftDataManager.createBackupPersistence()
        
        let coreDataTransactions = coreDataManager.createTransactionsPersistence()
        let coreDataAccounts = coreDataManager.createBankAccountsPersistence()
        let coreDataCategories = coreDataManager.createCategoriesPersistence()
        let coreDataBackups = coreDataManager.createBackupPersistence()
        
        try await swiftDataTransactions.clearAllTransactions()
        try await swiftDataAccounts.deleteBankAccount()
        try await swiftDataCategories.deleteAllCategories()
        try await swiftDataBackups.clearAllBackups()
        
        let transactions = try await coreDataTransactions.getAllTransactions()
        let account = try await coreDataAccounts.getBankAccount()
        let categories = try await coreDataCategories.getCategories()
        let backups = try await coreDataBackups.getBackupItems(entityType: "Transaction") as! [BackupItem<Transaction>]
        
        print("📊 Migrating \(transactions.count) transactions")
        try await swiftDataTransactions.saveTransactions(transactions)
        
        if let account = account {
            print("📊 Migrating 1 account")
            _ = try await swiftDataAccounts.saveBankAccount(account)
        }
        
        print("📊 Migrating \(categories.count) categories")
        try await swiftDataCategories.saveCategories(categories)
        
        print("📊 Migrating \(backups.count) backup items")
        for backup in backups {
            try await swiftDataBackups.createBackup(backup)
        }
        
        print("✅ Migration completed: CoreData → SwiftData")
    }
    
    func clearSwiftDataStorage() async throws {
        print("🗑️ Clearing SwiftData storage")
        try swiftDataManager.resetDatabase()
    }
    
    func clearCoreDataStorage() async throws {
        print("🗑️ Clearing CoreData storage")
        try coreDataManager.resetDatabase()
    }
    
    func getMigrationStats() async throws -> MigrationStats {
        let swiftDataStats = try await swiftDataManager.getDatabaseStats()
        let coreDataStats = try await coreDataManager.getDatabaseStats()
        
        return MigrationStats(
            swiftDataTransactions: swiftDataStats.transactionsCount,
            swiftDataAccounts: swiftDataStats.accountsCount,
            swiftDataCategories: swiftDataStats.categoriesCount,
            swiftDataBackups: swiftDataStats.backupItemsCount,
            coreDataTransactions: coreDataStats.transactionsCount,
            coreDataAccounts: coreDataStats.accountsCount,
            coreDataCategories: coreDataStats.categoriesCount,
            coreDataBackups: coreDataStats.backupItemsCount
        )
    }
}

final class AutoMigrationService {
    
    private let settingsService: SettingsServiceProtocol
    private let migrationService: DataMigrationProtocol
    private var lastKnownStorageType: StorageType
    
    init(
        settingsService: SettingsServiceProtocol,
        migrationService: DataMigrationProtocol
    ) {
        self.settingsService = settingsService
        self.migrationService = migrationService
        self.lastKnownStorageType = settingsService.storageType
        
        startObservingStorageTypeChanges()
    }
    
    private func startObservingStorageTypeChanges() {
        Task { @MainActor in
            for await newStorageType in settingsService.storageTypePublisher.values {
                if newStorageType != lastKnownStorageType {
                    await handleStorageTypeChange(from: lastKnownStorageType, to: newStorageType)
                    lastKnownStorageType = newStorageType
                }
            }
        }
    }
    
    private func handleStorageTypeChange(from oldType: StorageType, to newType: StorageType) async {
        guard oldType != newType else { return }
        
        print("🔄 Storage type changed: \(oldType.displayName) → \(newType.displayName)")
        
        do {
            switch (oldType, newType) {
            case (.swiftData, .coreData):
                try await migrationService.migrateFromSwiftDataToCoreData()
                try await migrationService.clearSwiftDataStorage()
                
            case (.coreData, .swiftData):
                try await migrationService.migrateFromCoreDataToSwiftData()
                try await migrationService.clearCoreDataStorage()
                
            default:
                break
            }
            
            let stats = try await migrationService.getMigrationStats()
            print("📊 Migration completed successfully:")
            print("   SwiftData: \(stats.swiftDataTransactions) transactions, \(stats.swiftDataAccounts) accounts")
            print("   CoreData: \(stats.coreDataTransactions) transactions, \(stats.coreDataAccounts) accounts")
            
        } catch {
            print("❌ Migration failed: \(error.localizedDescription)")
        }
    }
} 
