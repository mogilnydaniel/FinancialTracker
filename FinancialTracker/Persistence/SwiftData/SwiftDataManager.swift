import Foundation
import SwiftData

final class SwiftDataManager {

    
    static let shared = SwiftDataManager()

    
    private var _modelContainer: ModelContainer?

    var modelContainer: ModelContainer {
        get throws {
            if let container = _modelContainer {
                return container
            }
            
            let container = try createModelContainer()
            _modelContainer = container
            return container
        }
    }
    
    
    private init() {}
    
    
    private func createModelContainer() throws -> ModelContainer {
        let schema = Schema([
            TransactionEntity.self,
            BackupEntity.self,
            BankAccountEntity.self,
            CategoryEntity.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    func createTransactionsPersistence() throws -> SwiftDataTransactionsPersistence {
        let container = try modelContainer
        return SwiftDataTransactionsPersistence(modelContainer: container)
    }
    
    func createBackupPersistence() throws -> SwiftDataBackupPersistence {
        let container = try modelContainer
        return SwiftDataBackupPersistence(modelContainer: container)
    }
    
    func createBankAccountsPersistence() throws -> SwiftDataBankAccountsPersistence {
        let container = try modelContainer
        return SwiftDataBankAccountsPersistence(modelContainer: container)
    }
    
    func createCategoriesPersistence() throws -> SwiftDataCategoriesPersistence {
        let container = try modelContainer
        return SwiftDataCategoriesPersistence(modelContainer: container)
    }
    
    func resetDatabase() throws {
        _modelContainer = nil
        
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let databaseFiles = try fileManager.contentsOfDirectory(
            at: documentsPath,
            includingPropertiesForKeys: nil
        ).filter { url in
            url.pathExtension == "sqlite" || 
            url.pathExtension == "sqlite-wal" || 
            url.pathExtension == "sqlite-shm"
        }
        
        for file in databaseFiles {
            try fileManager.removeItem(at: file)
        }
        
        _ = try modelContainer
    }
    
    func getDatabaseStats() async throws -> DatabaseStats {
        let container = try modelContainer
        let context = ModelContext(container)
        
        let transactionsCount = try context.fetchCount(FetchDescriptor<TransactionEntity>())
        let backupCount = try context.fetchCount(FetchDescriptor<BackupEntity>())
        let accountsCount = try context.fetchCount(FetchDescriptor<BankAccountEntity>())
        let categoriesCount = try context.fetchCount(FetchDescriptor<CategoryEntity>())
        
        return DatabaseStats(
            transactionsCount: transactionsCount,
            backupItemsCount: backupCount,
            accountsCount: accountsCount,
            categoriesCount: categoriesCount
        )
    }
}

struct DatabaseStats {
    let transactionsCount: Int
    let backupItemsCount: Int
    let accountsCount: Int
    let categoriesCount: Int
    
    var totalRecords: Int {
        transactionsCount + backupItemsCount + accountsCount + categoriesCount
    }
}

extension ModelContainer {
    
    func newContext() -> ModelContext {
        ModelContext(self)
    }
    
    @MainActor
    func performInContext<T>(_ operation: (ModelContext) throws -> T) throws -> T {
        let context = newContext()
        let result = try operation(context)
        try context.save()
        return result
    }
}


extension SwiftDataManager {
    
    enum SwiftDataError: LocalizedError {
        case containerCreationFailed(Error)
        case databaseResetFailed(Error)
        case contextOperationFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .containerCreationFailed(let error):
                return "Failed to create ModelContainer: \(error.localizedDescription)"
            case .databaseResetFailed(let error):
                return "Failed to reset database: \(error.localizedDescription)"
            case .contextOperationFailed(let error):
                return "Context operation failed: \(error.localizedDescription)"
            }
        }
    }
} 
