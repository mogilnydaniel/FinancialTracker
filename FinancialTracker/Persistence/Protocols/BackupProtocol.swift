import Foundation

enum BackupAction: String, Codable, CaseIterable {
    case create = "create"
    case update = "update" 
    case delete = "delete"
}

struct BackupItem<T: Codable>: Codable, Identifiable {
    let id: UUID
    let action: BackupAction
    let timestamp: Date
    let payload: T?
    let entityId: Int?
    
    init(action: BackupAction, payload: T? = nil, entityId: Int? = nil) {
        self.id = UUID()
        self.action = action
        self.timestamp = Date()
        self.payload = payload
        self.entityId = entityId
    }
    
    static func create(payload: T) -> BackupItem<T> {
        BackupItem(action: .create, payload: payload)
    }
    
    static func update(payload: T) -> BackupItem<T> {
        BackupItem(action: .update, payload: payload)
    }
    
    static func delete(entityId: Int) -> BackupItem<T> {
        BackupItem(action: .delete, entityId: entityId)
    }
}

protocol BackupProtocol: Sendable {
    
    func createBackup<T: Codable>(_ item: BackupItem<T>) async throws
    
    func getBackupItems(entityType: String) async throws -> [any Codable]
    
    func removeBackup(entityType: String, entityId: String) async throws
    
    func getAllBackupItems() async throws -> [any Codable]
    
    func clearAllBackups() async throws
    
    func getBackupCount() async throws -> Int
} 
