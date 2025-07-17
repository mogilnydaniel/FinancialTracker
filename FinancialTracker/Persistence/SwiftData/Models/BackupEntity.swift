import Foundation
import SwiftData

@Model
final class BackupEntity {
    
    
    @Attribute(.unique) var id: String
    var actionRawValue: String
    var timestamp: Date
    var payloadData: Data?
    var entityId: Int?
    var entityType: String
    
    
    var action: BackupAction {
        get {
            return BackupAction(rawValue: actionRawValue) ?? .create
        }
        set {
            actionRawValue = newValue.rawValue
        }
    }
    
    var backupId: UUID {
        get {
            return UUID(uuidString: id) ?? UUID()
        }
        set {
            id = newValue.uuidString
        }
    }
    
    init(
        id: UUID = UUID(),
        action: BackupAction,
        timestamp: Date = Date(),
        payloadData: Data? = nil,
        entityId: Int? = nil,
        entityType: String
    ) {
        self.id = id.uuidString
        self.actionRawValue = action.rawValue
        self.timestamp = timestamp
        self.payloadData = payloadData
        self.entityId = entityId
        self.entityType = entityType
    }
    
    convenience init(from backupItem: BackupItem<Transaction>) throws {
        let payloadData: Data?
        if let payload = backupItem.payload {
            payloadData = try JSONEncoder().encode(payload)
        } else {
            payloadData = nil
        }
        
        self.init(
            id: backupItem.id,
            action: backupItem.action,
            timestamp: backupItem.timestamp,
            payloadData: payloadData,
            entityId: backupItem.entityId,
            entityType: "Transaction"
        )
    }
    
    func toTransactionBackupItem() throws -> BackupItem<Transaction> {
        let payload: Transaction?
        
        if let payloadData = payloadData {
            payload = try JSONDecoder().decode(Transaction.self, from: payloadData)
        } else {
            payload = nil
        }
        
        switch action {
        case .create:
            guard let payload = payload else {
                throw PersistenceError.invalidBackupData("Create action requires payload")
            }
            return .create(payload: payload)
        case .update:
            guard let payload = payload else {
                throw PersistenceError.invalidBackupData("Update action requires payload")
            }
            return .update(payload: payload)
        case .delete:
            guard let entityId = entityId else {
                throw PersistenceError.invalidBackupData("Delete action requires entityId")
            }
            return .delete(entityId: entityId)
        }
    }
    
    func update(from backupItem: BackupItem<Transaction>) throws {
        self.backupId = backupItem.id
        self.action = backupItem.action
        self.timestamp = backupItem.timestamp
        self.entityId = backupItem.entityId
        
        if let payload = backupItem.payload {
            self.payloadData = try JSONEncoder().encode(payload)
        } else {
            self.payloadData = nil
        }
    }
}

enum PersistenceError: LocalizedError {
    case invalidBackupData(String)
    case conversionFailed(String)
    case notFound
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidBackupData(let message):
            return "Invalid backup data: \(message)"
        case .conversionFailed(let message):
            return "Conversion failed: \(message)"
        case .notFound:
            return "Entity not found"
        case .fetchFailed(let message):
            return "Fetch failed: \(message)"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        }
    }
}


extension Array where Element == BackupEntity {
    

    func toTransactionBackupItems() throws -> [BackupItem<Transaction>] {
        return try compactMap { entity in
            guard entity.entityType == "Transaction" else { return nil }
            return try entity.toTransactionBackupItem()
        }
    }
}

extension Array where Element == BackupItem<Transaction> {
    
    func toEntities() throws -> [BackupEntity] {
        return try map { try BackupEntity(from: $0) }
    }
} 
