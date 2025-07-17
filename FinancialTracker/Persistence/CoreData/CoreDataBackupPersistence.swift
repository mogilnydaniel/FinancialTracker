import Foundation
import CoreData

final class CoreDataBackupPersistence: BackupProtocol {
    
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    func createBackup<T: Codable>(_ item: BackupItem<T>) async throws {
        try await container.performInBackground { context in
            if T.self == Transaction.self {
                let transactionItem = item as! BackupItem<Transaction>
                _ = try CDBackupEntity(context: context, from: transactionItem)
                try context.save()
            }
        }
    }
    
    func getBackupItems(entityType: String) async throws -> [any Codable] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "entityType == %@", entityType)
            
            let entities = try context.fetch(request)
            
            if entityType == "Transaction" {
                return try entities.toTransactionBackupItems() as [any Codable]
            }
            return []
        }
    }
    
    func removeBackup(entityType: String, entityId: String) async throws {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "entityType == %@ AND entityId == %d", entityType, Int(entityId) ?? 0)
            
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    func getAllBackupItems() async throws -> [any Codable] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            let entities = try context.fetch(request)
            
            return try entities.filter { $0.entityType == "Transaction" }
                               .toTransactionBackupItems() as [any Codable]
        }
    }
    
    func clearAllBackups() async throws {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            let entities = try context.fetch(request)
            
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    func getBackupCount() async throws -> Int {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            return try context.count(for: request)
        }
    }
    
    func getAllTransactionBackupItems() async throws -> [BackupItem<Transaction>] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "entityType == %@", "Transaction")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBackupEntity.timestamp, ascending: false)]
            
            let entities = try context.fetch(request)
            return try entities.toTransactionBackupItems()
        }
    }
    
    func getBackupItem(by id: UUID) async throws -> BackupItem<Transaction>? {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@ AND entityType == %@", id.uuidString, "Transaction")
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return try entities.first?.toTransactionBackupItem()
        }
    }
    
    func saveBackupItem(_ item: BackupItem<Transaction>) async throws {
        try await container.performInBackground { context in
            if let existingEntity = try self.getBackupEntityInContext(by: item.id, context: context) {
                try existingEntity.update(from: item)
            } else {
                _ = try CDBackupEntity(context: context, from: item)
            }
            try context.save()
        }
    }
    
    func deleteBackupItem(by id: UUID) async throws {
        try await container.performInBackground { context in
            guard let entity = try self.getBackupEntityInContext(by: id, context: context) else {
                return
            }
            
            context.delete(entity)
            try context.save()
        }
    }
    
    func deleteBackupItems(by ids: [UUID]) async throws {
        try await container.performInBackground { context in
            let uuidStrings = ids.map { $0.uuidString }
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@ AND entityType == %@", uuidStrings, "Transaction")
            
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    func clearAllBackupItems() async throws {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "entityType == %@", "Transaction")
            let entities = try context.fetch(request)
            
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    func backupItemsCount() async throws -> Int {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "entityType == %@", "Transaction")
            return try context.count(for: request)
        }
    }
    
    func getBackupItems(action: BackupAction) async throws -> [BackupItem<Transaction>] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "actionRawValue == %@ AND entityType == %@", action.rawValue, "Transaction")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBackupEntity.timestamp, ascending: false)]
            
            let entities = try context.fetch(request)
            return try entities.toTransactionBackupItems()
        }
    }
    
    func getBackupItems(olderThan date: Date) async throws -> [BackupItem<Transaction>] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "timestamp < %@ AND entityType == %@", date as NSDate, "Transaction")
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBackupEntity.timestamp, ascending: false)]
            
            let entities = try context.fetch(request)
            return try entities.toTransactionBackupItems()
        }
    }
    
    func createBackupItemFor(transaction: Transaction, action: BackupAction) async throws {
        let backupItem: BackupItem<Transaction>
        
        switch action {
        case .create, .update:
            backupItem = BackupItem(action: action, payload: transaction)
        case .delete:
            backupItem = BackupItem(action: .delete, entityId: transaction.id)
        }
        
        try await saveBackupItem(backupItem)
    }
    
    func findBackupItem(for entityId: Int, action: BackupAction) async throws -> BackupItem<Transaction>? {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "entityId == %d AND actionRawValue == %@ AND entityType == %@", 
                                          entityId, action.rawValue, "Transaction")
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return try entities.first?.toTransactionBackupItem()
        }
    }
    
    func removeBackupItem(for entityId: Int, action: BackupAction) async throws {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
            request.predicate = NSPredicate(format: "entityId == %d AND actionRawValue == %@ AND entityType == %@", 
                                          entityId, action.rawValue, "Transaction")
            
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    private func getBackupEntityInContext(by id: UUID, context: NSManagedObjectContext) throws -> CDBackupEntity? {
        let request: NSFetchRequest<CDBackupEntity> = CDBackupEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND entityType == %@", id.uuidString, "Transaction")
        request.fetchLimit = 1
        
        let entities = try context.fetch(request)
        return entities.first
    }
} 