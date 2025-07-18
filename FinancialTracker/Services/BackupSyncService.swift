import Foundation

protocol BackupSyncServiceProtocol: Sendable {
    func syncPendingBackups() async throws
    func syncTransactionBackups() async throws
    func syncBankAccountBackups() async throws
    func clearSyncedBackups() async throws
    func getBackupCount() async throws -> Int
}

actor BackupSyncService: BackupSyncServiceProtocol {
    private let backup: any BackupProtocol
    private let networkClient: NetworkClient
    private let transactionsPersistence: TransactionsPersistenceProtocol
    private let bankAccountsPersistence: BankAccountsPersistenceProtocol
    
    init(
        backup: any BackupProtocol,
        networkClient: NetworkClient,
        transactionsPersistence: TransactionsPersistenceProtocol,
        bankAccountsPersistence: BankAccountsPersistenceProtocol
    ) {
        self.backup = backup
        self.networkClient = networkClient
        self.transactionsPersistence = transactionsPersistence
        self.bankAccountsPersistence = bankAccountsPersistence
    }
    
    func syncPendingBackups() async throws {
        try await syncTransactionBackups()
        try await syncBankAccountBackups()
        try await clearSyncedBackups()
    }
    
    func syncTransactionBackups() async throws {
        let transactionBackups = try await backup.getBackupItems(entityType: "Transaction")
        
        for backupData in transactionBackups {
            guard let backupEntity = backupData as? BackupItem<Transaction> else { continue }
            
            switch backupEntity.action {
            case .create:
                if let payload = backupEntity.payload {
                    try await syncCreateTransaction(payload)
                }
            case .update:
                if let payload = backupEntity.payload {
                    try await syncUpdateTransaction(payload)
                }
            case .delete:
                if let entityId = backupEntity.entityId {
                    try await syncDeleteTransaction(entityId)
                }
            }
        }
    }
    
    func syncBankAccountBackups() async throws {
        let accountBackups = try await backup.getBackupItems(entityType: "BankAccount")
        
        for backupData in accountBackups {
            guard let backupEntity = backupData as? BackupItem<BankAccount> else { continue }
            
            switch backupEntity.action {
            case .update:
                if let payload = backupEntity.payload {
                    try await syncUpdateBankAccount(payload)
                }
            default:
                break
            }
        }
    }
    
    func clearSyncedBackups() async throws {
        try await backup.clearAllBackups()
    }
    
    func getBackupCount() async throws -> Int {
        return try await backup.getBackupCount()
    }
    
    private func syncCreateTransaction(_ transaction: Transaction) async throws {
        let request = TransactionRequest(
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment
        )
        
        let endpoint = Endpoint(path: "/transactions", method: .post)
        
        struct Body: Encodable {
            let accountId: Int
            let categoryId: Int
            let amount: String
            let transactionDate: String
            let comment: String?
        }
        
        let formatter = ISO8601DateFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        let amountString = numberFormatter.string(from: request.amount as NSDecimalNumber) ?? "0.00"
        
        let body = Body(
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: amountString,
            transactionDate: formatter.string(from: request.transactionDate),
            comment: request.comment
        )
        
        let _: TransactionDTO = try await networkClient.request(endpoint, body: body, encoder: JSONCoding.encoder)
        try await backup.removeBackup(entityType: "Transaction", entityId: String(transaction.id))
    }
    
    private func syncUpdateTransaction(_ transaction: Transaction) async throws {
        let request = TransactionRequest(
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment
        )
        
        let endpoint = Endpoint(path: "/transactions/\(transaction.id)", method: .patch)
        
        struct Body: Encodable {
            let accountId: Int
            let categoryId: Int
            let amount: String
            let transactionDate: String
            let comment: String?
        }
        
        let formatter = ISO8601DateFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        let amountString = numberFormatter.string(from: request.amount as NSDecimalNumber) ?? "0.00"
        
        let body = Body(
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: amountString,
            transactionDate: formatter.string(from: request.transactionDate),
            comment: request.comment
        )
        
        let _: TransactionDTO = try await networkClient.request(endpoint, body: body, encoder: JSONCoding.encoder)
        try await backup.removeBackup(entityType: "Transaction", entityId: String(transaction.id))
    }
    
    private func syncDeleteTransaction(_ transactionId: Int) async throws {
        let endpoint = Endpoint(path: "/transactions/\(transactionId)", method: .delete)
        let _: TransactionDTO = try await networkClient.request(endpoint, body: Optional<String>.none)
        try await backup.removeBackup(entityType: "Transaction", entityId: String(transactionId))
    }
    
    private func syncUpdateBankAccount(_ account: BankAccount) async throws {
        struct UpdateAccountBody: Encodable {
            let name: String
            let balance: Decimal
            let currency: String
        }
        
        let body = UpdateAccountBody(
            name: account.name,
            balance: account.balance,
            currency: account.currency.code
        )
        
        let endpoint = Endpoint(path: "/accounts/\(account.id)", method: .patch)
        let _: BankAccountDTO = try await networkClient.request(endpoint, body: body, encoder: JSONCoding.encoder)
        try await backup.removeBackup(entityType: "BankAccount", entityId: String(account.id))
    }
} 