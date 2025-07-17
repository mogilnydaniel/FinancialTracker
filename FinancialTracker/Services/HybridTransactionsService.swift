import Foundation

actor HybridTransactionsService: TransactionsServiceProtocol {
    private let persistence: TransactionsPersistenceProtocol
    private let backup: any BackupProtocol
    private let networkClient: NetworkClient
    private let syncService: BackupSyncService?
    
    init(
        persistence: TransactionsPersistenceProtocol,
        backup: any BackupProtocol,
        networkClient: NetworkClient,
        syncService: BackupSyncService? = nil
    ) {
        self.persistence = persistence
        self.backup = backup
        self.networkClient = networkClient
        self.syncService = syncService
        
        Task { @MainActor in
            await setupNetworkMonitoring()
        }
    }
    
    private func setupNetworkMonitoring() async {
        Task { @MainActor in
            for await isConnected in NetworkConnectionDetector.shared.connectionStateChange.values {
                if isConnected {
                    Task {
                        await tryAutoSync()
                    }
                }
            }
        }
    }
    
    private func tryAutoSync() async {
        guard let syncService = syncService else { return }
        
        do {
            try await syncService.syncPendingBackups()
        } catch {
        }
    }
    
    func getTransactions(
        from startDate: Date,
        to endDate: Date,
        direction: Category.Direction
    ) async throws -> [Transaction] {
        let localTransactions = try await persistence.getTransactions(
            from: startDate,
            to: endDate
        )
        
        Task { @MainActor in
            await syncFromNetwork(startDate: startDate, endDate: endDate)
        }
        
        return localTransactions
    }
    
    func createTransaction(_ request: TransactionRequest) async throws -> Transaction {
        let transaction = Transaction(
            id: Int.random(in: 100000...999999),
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: request.amount,
            transactionDate: request.transactionDate,
            comment: request.comment,
            creationDate: Date(),
            modificationDate: Date()
        )
        
        let savedTransaction = try await persistence.createTransaction(transaction)
        
        await handleNetworkSync(
            action: .create,
            transaction: savedTransaction,
            request: request
        )
        
        NotificationCenter.default.post(
            name: .transactionDidChange,
            object: nil,
            userInfo: ["transaction": savedTransaction]
        )
        
        return savedTransaction
    }
    
    func updateTransaction(id: Int, with request: TransactionRequest) async throws -> Transaction {
        guard let oldTransaction = try await persistence.getTransaction(by: id) else {
            throw NSError(domain: "TransactionNotFound", code: 404, userInfo: nil)
        }
        
        let updatedTransaction = Transaction(
            id: id,
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: request.amount,
            transactionDate: request.transactionDate,
            comment: request.comment,
            creationDate: oldTransaction.creationDate,
            modificationDate: Date()
        )
        
        let savedTransaction = try await persistence.updateTransaction(updatedTransaction)
        
        await handleNetworkSync(
            action: .update,
            transaction: savedTransaction,
            request: request
        )
        
        NotificationCenter.default.post(
            name: .transactionDidChange,
            object: nil,
            userInfo: [
                "transaction": savedTransaction,
                "oldTransaction": oldTransaction
            ]
        )
        
        return savedTransaction
    }
    
    func deleteTransaction(withId id: Int) async throws -> Transaction {
        guard let transaction = try await persistence.deleteTransaction(by: id) else {
            throw NSError(domain: "TransactionNotFound", code: 404, userInfo: nil)
        }
        
        await handleNetworkSync(
            action: .delete,
            transaction: transaction,
            request: nil
        )
        
        NotificationCenter.default.post(
            name: .transactionDidChange,
            object: nil,
            userInfo: ["removedTransaction": transaction]
        )
        
        return transaction
    }
    
    private func handleNetworkSync(
        action: BackupAction,
        transaction: Transaction,
        request: TransactionRequest?
    ) async {
        do {
            switch action {
            case .create:
                guard let request = request else { return }
                _ = try await performNetworkCreate(request)
                try await backup.removeBackup(
                    entityType: "Transaction",
                    entityId: String(transaction.id)
                )
                
            case .update:
                guard let request = request else { return }
                _ = try await performNetworkUpdate(id: transaction.id, request: request)
                try await backup.removeBackup(
                    entityType: "Transaction",
                    entityId: String(transaction.id)
                )
                
            case .delete:
                _ = try await performNetworkDelete(id: transaction.id)
                try await backup.removeBackup(
                    entityType: "Transaction",
                    entityId: String(transaction.id)
                )
            }
        } catch {
            if action == .delete {
                try? await backup.createBackup(
                    BackupItem<Transaction>(
                        action: action,
                        payload: nil,
                        entityId: transaction.id
                    )
                )
            } else if let request = request {
                try? await backup.createBackup(
                    BackupItem<TransactionRequest>(
                        action: action,
                        payload: request,
                        entityId: transaction.id
                    )
                )
            }
        }
    }
    
    private func performNetworkCreate(_ request: TransactionRequest) async throws -> Transaction {
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
        
        let endpoint = Endpoint(path: "/transactions", method: .post)
        let dto: TransactionDTO = try await networkClient.request(endpoint, body: body, encoder: JSONCoding.encoder)
        
        guard let transaction = TransactionDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert TransactionDTO to Transaction"])
        }
        
        return transaction
    }
    
    private func performNetworkUpdate(id: Int, request: TransactionRequest) async throws -> Transaction {
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
        
        let endpoint = Endpoint(path: "/transactions/\(id)", method: .put)
        let dto: TransactionDTO = try await networkClient.request(endpoint, body: body, encoder: JSONCoding.encoder)
        
        guard let transaction = TransactionDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert TransactionDTO to Transaction"])
        }
        
        return transaction
    }
    
    private func performNetworkDelete(id: Int) async throws -> Transaction {
        let endpoint = Endpoint(path: "/transactions/\(id)", method: .delete)
        let dto: TransactionDTO = try await networkClient.request(endpoint, body: Optional<Int>.none)
        
        guard let transaction = TransactionDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert TransactionDTO to Transaction"])
        }
        
        return transaction
    }
    
    private func syncFromNetwork(startDate: Date, endDate: Date) async {
        do {
            let accountId = 1
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let query = [
                URLQueryItem(name: "startDate", value: formatter.string(from: startDate)),
                URLQueryItem(name: "endDate", value: formatter.string(from: endDate))
            ]
            
            var endpoint = Endpoint(path: "/transactions/account/\(accountId)/period", method: .get)
            endpoint.query = query
            
            let dtoList: [TransactionDTO] = try await networkClient.request(endpoint, body: Optional<Int>.none)
            let networkTransactions = dtoList.compactMap { TransactionDTOToDomainConverter.convert($0) }
            
            try await persistence.syncTransactions(networkTransactions)
            
        } catch {
        }
    }
} 
