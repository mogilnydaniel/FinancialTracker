import Foundation
import SwiftData

@ModelActor
actor SwiftDataBackupPersistence: BackupProtocol {
    
    func createBackup<T: Codable>(_ item: BackupItem<T>) async throws {
        let payloadData: Data?
        if let payload = item.payload {
            payloadData = try JSONEncoder().encode(payload)
        } else {
            payloadData = nil
        }
        
        let entity = BackupEntity(
            id: item.id,
            action: item.action,
            timestamp: item.timestamp,
            payloadData: payloadData,
            entityId: item.entityId,
            entityType: String(describing: T.self)
        )
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func getBackupItems(entityType: String) async throws -> [any Codable] {
        let predicate = #Predicate<BackupEntity> { entity in
            entity.entityType == entityType
        }
        let descriptor = FetchDescriptor<BackupEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let entities = try modelContext.fetch(descriptor)
        
        var items: [any Codable] = []
        for entity in entities {
            if let payloadData = entity.payloadData {
                if entityType == "Transaction" {
                    if let transaction = try? JSONDecoder().decode(Transaction.self, from: payloadData) {
                        items.append(transaction)
                    }
                }
            }
        }
        return items
    }
    
    func removeBackup(entityType: String, entityId: String) async throws {
        let entityIdInt = Int(entityId) ?? 0
        let predicate = #Predicate<BackupEntity> { entity in
            entity.entityType == entityType && entity.entityId == entityIdInt
        }
        let descriptor = FetchDescriptor<BackupEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }
    
    func getAllBackupItems() async throws -> [any Codable] {
        let descriptor = FetchDescriptor<BackupEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let entities = try modelContext.fetch(descriptor)
        
        var items: [any Codable] = []
        for entity in entities {
            if let payloadData = entity.payloadData {
                if entity.entityType == "Transaction" {
                    if let transaction = try? JSONDecoder().decode(Transaction.self, from: payloadData) {
                        items.append(transaction)
                    }
                }
            }
        }
        return items
    }
    
    func clearAllBackups() async throws {
        let descriptor = FetchDescriptor<BackupEntity>()
        let entities = try modelContext.fetch(descriptor)
        
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }
    
    func getBackupCount() async throws -> Int {
        let descriptor = FetchDescriptor<BackupEntity>()
        return try modelContext.fetchCount(descriptor)
    }
} 