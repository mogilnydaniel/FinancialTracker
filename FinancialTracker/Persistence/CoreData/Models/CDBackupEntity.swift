import Foundation
import CoreData

@objc(CDBackupEntity)
public class CDBackupEntity: NSManagedObject {
    
    var action: BackupAction {
        get {
            return BackupAction(rawValue: actionRawValue ?? "create") ?? .create
        }
        set {
            actionRawValue = newValue.rawValue
        }
    }
    
    var backupId: UUID {
        get {
            return UUID(uuidString: id ?? "") ?? UUID()
        }
        set {
            id = newValue.uuidString
        }
    }
    
    convenience init(context: NSManagedObjectContext, from backupItem: BackupItem<Transaction>) throws {
        self.init(context: context)
        self.backupId = backupItem.id
        self.action = backupItem.action
        self.timestamp = backupItem.timestamp
        self.entityType = "Transaction"
        self.entityId = backupItem.entityId.map(Int32.init) ?? 0
        
        if let payload = backupItem.payload {
            self.payloadData = try JSONEncoder().encode(payload)
        }
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
            guard entityId != 0 else {
                throw PersistenceError.invalidBackupData("Delete action requires entityId")
            }
            return .delete(entityId: Int(entityId))
        }
    }
    
    func update(from backupItem: BackupItem<Transaction>) throws {
        self.backupId = backupItem.id
        self.action = backupItem.action
        self.timestamp = backupItem.timestamp
        self.entityId = backupItem.entityId.map(Int32.init) ?? 0
        
        if let payload = backupItem.payload {
            self.payloadData = try JSONEncoder().encode(payload)
        } else {
            self.payloadData = nil
        }
    }
}

extension CDBackupEntity {
    
    @NSManaged public var id: String?
    @NSManaged public var actionRawValue: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var payloadData: Data?
    @NSManaged public var entityId: Int32
    @NSManaged public var entityType: String?
}

extension CDBackupEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBackupEntity> {
        return NSFetchRequest<CDBackupEntity>(entityName: "CDBackupEntity")
    }
}

extension Array where Element == CDBackupEntity {
    
    func toTransactionBackupItems() throws -> [BackupItem<Transaction>] {
        return try compactMap { entity in
            guard entity.entityType == "Transaction" else { return nil }
            return try entity.toTransactionBackupItem()
        }
    }
}

extension Array where Element == BackupItem<Transaction> {
    
    func toCoreDataEntities(context: NSManagedObjectContext) throws -> [CDBackupEntity] {
        return try map { try CDBackupEntity(context: context, from: $0) }
    }
} 