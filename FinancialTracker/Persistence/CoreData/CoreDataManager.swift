import Foundation
import CoreData

final class CoreDataManager {
    
    static let shared = CoreDataManager()
    
    private var _persistentContainer: NSPersistentContainer?
    private var _coreDataAvailable: Bool = true
    
    var persistentContainer: NSPersistentContainer {
        if let container = _persistentContainer {
            return container
        }
        
        let container = createPersistentContainer()
        _persistentContainer = container
        return container
    }
    
    var isCoreDataAvailable: Bool {
        return _coreDataAvailable
    }
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    private init() {}
    
    private func createPersistentContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "FinancialTracker")
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error {
                #if DEBUG
                print("❌ Failed to load Core Data stack: \(error)")
                print("⚠️  CoreData functionality will be disabled. Using SwiftData only.")
                #endif
                self?._coreDataAvailable = false
            } else {
                #if DEBUG
                print("✅ CoreData stack loaded successfully")
                #endif
                self?._coreDataAvailable = true
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }
    
    func createTransactionsPersistence() -> CoreDataTransactionsPersistence {
        CoreDataTransactionsPersistence(container: persistentContainer)
    }
    
    func createBackupPersistence() -> CoreDataBackupPersistence {
        CoreDataBackupPersistence(container: persistentContainer)
    }
    
    func createBankAccountsPersistence() -> CoreDataBankAccountsPersistence {
        CoreDataBankAccountsPersistence(container: persistentContainer)
    }
    
    func createCategoriesPersistence() -> CoreDataCategoriesPersistence {
        CoreDataCategoriesPersistence(container: persistentContainer)
    }
    
    func save() throws {
        guard _coreDataAvailable else {
            throw CoreDataError.containerCreationFailed(NSError(domain: "CoreDataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "CoreData is not available"]))
        }
        
        let context = viewContext
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    func resetDatabase() throws {
        _persistentContainer = nil
        
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
        
        _ = persistentContainer
    }
    
    func getDatabaseStats() async throws -> DatabaseStats {
        guard _coreDataAvailable else {
            return DatabaseStats(
                transactionsCount: 0,
                backupItemsCount: 0,
                accountsCount: 0,
                categoriesCount: 0
            )
        }
        
        let context = persistentContainer.newBackgroundContext()
        
        return try await context.perform {
            let transactionsCount = try context.count(for: CDTransactionEntity.fetchRequest())
            let backupCount = try context.count(for: CDBackupEntity.fetchRequest())
            let accountsCount = try context.count(for: CDBankAccountEntity.fetchRequest())
            let categoriesCount = try context.count(for: CDCategoryEntity.fetchRequest())
            
            return DatabaseStats(
                transactionsCount: transactionsCount,
                backupItemsCount: backupCount,
                accountsCount: accountsCount,
                categoriesCount: categoriesCount
            )
        }
    }
}

extension NSPersistentContainer {
    
    func performInBackground<T>(_ operation: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let context = newBackgroundContext()
        
        return try await context.perform {
            let result = try operation(context)
            if context.hasChanges {
                try context.save()
            }
            return result
        }
    }
}

extension CoreDataManager {
    
    enum CoreDataError: LocalizedError {
        case containerCreationFailed(Error)
        case databaseResetFailed(Error)
        case contextOperationFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .containerCreationFailed(let error):
                return "Failed to create NSPersistentContainer: \(error.localizedDescription)"
            case .databaseResetFailed(let error):
                return "Failed to reset database: \(error.localizedDescription)"
            case .contextOperationFailed(let error):
                return "Context operation failed: \(error.localizedDescription)"
            }
        }
    }
} 