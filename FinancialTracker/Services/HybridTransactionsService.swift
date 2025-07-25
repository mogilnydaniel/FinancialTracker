import Foundation

actor HybridTransactionsService: TransactionsServiceProtocol {
    private let persistence: TransactionsPersistenceProtocol
    private let backup: any BackupProtocol
    private let networkClient: NetworkClient
    private let syncService: BackupSyncService?
    private static var globalLastSyncTime: Date = .distantPast
    private var syncTask: Task<Void, Never>?
    
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
                    await scheduleAutoSync()
                }
            }
        }
    }
    
    private func scheduleAutoSync() async {
        syncTask?.cancel()
        syncTask = Task {
            do {
                try await Task.sleep(for: .seconds(2))
                await tryAutoSync()
            } catch {
            }
        }
    }
    
    private func tryAutoSync() async {
        guard let syncService = syncService else { return }
        
        let now = Date()
        guard now.timeIntervalSince(Self.globalLastSyncTime) > 30 else { return }
        
        do {
            try await syncService.syncPendingBackups()
            Self.globalLastSyncTime = now
        } catch {
        }
    }
    
    func getTransactions(
        from startDate: Date,
        to endDate: Date,
        direction: Category.Direction
    ) async throws -> [Transaction] {
        #if DEBUG
        print("HybridTransactionsService.getTransactions called with \(direction) from \(startDate) to \(endDate)")
        #endif
        
        let localTransactions = try await persistence.getTransactions(
            from: startDate,
            to: endDate
        )
        
        let now = Date()
        let shouldSync = now.timeIntervalSince(Self.globalLastSyncTime) > 60
        
        
        let isFirstLaunch = Self.globalLastSyncTime == .distantPast
        
        if shouldSync && (localTransactions.isEmpty || isFirstLaunch) {
            await syncFromNetwork(startDate: startDate, endDate: endDate)
            
            let updatedTransactions = try await persistence.getTransactions(
                from: startDate,
                to: endDate
            )
            
            return updatedTransactions
        } else if shouldSync {
            
            Task { @MainActor in
                await syncFromNetwork(startDate: startDate, endDate: endDate)
            }
        }
        

        
        return localTransactions
    }
    
    func createTransaction(_ request: TransactionRequest) async throws -> Transaction {
        do {
            let networkTransaction = try await performNetworkCreate(request)
            
            let transaction = Transaction(
                id: networkTransaction.id,
                accountId: request.accountId,
                categoryId: request.categoryId,
                amount: request.amount,
                transactionDate: request.transactionDate,
                comment: request.comment,
                creationDate: Date(),
                modificationDate: Date()
            )
            
            let savedTransaction = try await persistence.createTransaction(transaction)
            
            NotificationCenter.default.post(
                name: .transactionDidChange,
                object: nil,
                userInfo: ["transaction": savedTransaction]
            )
            
            return savedTransaction
            
        } catch {
            throw error
        }
    }
    
    func updateTransaction(id: Int, with request: TransactionRequest) async throws -> Transaction {
        guard let oldTransaction = try await persistence.getTransaction(by: id) else {
            throw NSError(domain: "TransactionNotFound", code: 0, userInfo: [NSLocalizedDescriptionKey: "Транзакция не найдена"])
        }
        
        
        do {
            let networkTransaction = try await performNetworkUpdate(id: id, request: request)
            
            
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
            
            NotificationCenter.default.post(
                name: .transactionDidChange,
                object: nil,
                userInfo: [
                    "transaction": savedTransaction,
                    "oldTransaction": oldTransaction
                ]
            )
            
            return savedTransaction
            
        } catch {
            throw error
        }
    }
    
    func deleteTransaction(withId id: Int) async throws -> Transaction {
        
        guard let transaction = try await persistence.getTransaction(by: id) else {
            throw NSError(domain: "TransactionNotFound", code: 0, userInfo: [NSLocalizedDescriptionKey: "Транзакция не найдена"])
        }
        
        
        do {
            try await performNetworkDelete(id: id)
            
            
            guard let deletedTransaction = try await persistence.deleteTransaction(by: id) else {
                throw NSError(domain: "TransactionNotFound", code: 0, userInfo: [NSLocalizedDescriptionKey: "Транзакция не найдена"])
            }
            
            NotificationCenter.default.post(
                name: .transactionDidChange,
                object: nil,
                userInfo: ["removedTransaction": deletedTransaction]
            )
            
            return deletedTransaction
            
        } catch {
            throw error
        }
    }
    

    
    private func performNetworkCreate(_ request: TransactionRequest) async throws -> Transaction {
        struct Body: Encodable {
            let accountId: Int
            let categoryId: Int
            let amount: String
            let transactionDate: String
            let comment: String
        }
        
        let formatter = ISO8601DateFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.usesGroupingSeparator = false
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let amountString = numberFormatter.string(from: request.amount as NSDecimalNumber) ?? "0.00"
        
        let body = Body(
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: amountString,
            transactionDate: formatter.string(from: request.transactionDate),
            comment: request.comment ?? ""
        )
        
        #if DEBUG
        print("Creating transaction via network:")
        print("   Account ID: \(request.accountId)")
        print("   Category ID: \(request.categoryId)")
        print("   Amount: \(amountString)")
        print("   Date: \(formatter.string(from: request.transactionDate))")
        print("   Comment: \(request.comment ?? "nil")")
        #endif
        
        let endpoint = Endpoint(path: "/transactions", method: .post)
        let dto: TransactionDTO = try await networkClient.request(endpoint, body: body, encoder: JSONCoding.encoder)
        
        #if DEBUG

        #endif
        
        guard let transaction = TransactionDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ошибка обработки данных"])
        }
        
        return transaction
    }
    
    private func performNetworkUpdate(id: Int, request: TransactionRequest) async throws -> Transaction {
        struct Body: Encodable {
            let accountId: Int
            let categoryId: Int
            let amount: String
            let transactionDate: String
            let comment: String
        }
        
        let formatter = ISO8601DateFormatter()
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.usesGroupingSeparator = false
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let amountString = numberFormatter.string(from: request.amount as NSDecimalNumber) ?? "0.00"
        
        let body = Body(
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: amountString,
            transactionDate: formatter.string(from: request.transactionDate),
            comment: request.comment ?? ""
        )
        
        #if DEBUG
        print("Updating transaction \(id) via network:")
        print("   Account ID: \(request.accountId)")
        print("   Category ID: \(request.categoryId)")
        print("   Amount: \(amountString)")
        print("   Date: \(formatter.string(from: request.transactionDate))")
        print("   Comment: \(request.comment ?? "nil")")
        #endif
        
        let endpoint = Endpoint(path: "/transactions/\(id)", method: .put)
        let dto: TransactionDTO = try await networkClient.request(endpoint, body: body, encoder: JSONCoding.encoder)
        
        #if DEBUG

        #endif
        
        guard let transaction = TransactionDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Ошибка обработки данных"])
        }
        
        return transaction
    }
    
    private func performNetworkDelete(id: Int) async throws {
        let endpoint = Endpoint(path: "/transactions/\(id)", method: .delete)
        let _: Empty = try await networkClient.request(endpoint, body: Optional<Int>.none)
    }
    
    private func syncFromNetwork(startDate: Date, endDate: Date) async {
        do {
            let accountId = 1
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "ru_RU")
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
            
            Self.globalLastSyncTime = Date()
            
            #if DEBUG
            try await clearDuplicateTransactions()
            #endif
            
        } catch {
            #if DEBUG
            print("Failed to sync from network: \(error)")
            #endif
        }
    }
    
    
    func clearDuplicateTransactions() async throws {
        #if DEBUG
        let allTransactions = try await persistence.getAllTransactions()
        print("🔍 Found \(allTransactions.count) total transactions, checking for duplicates...")
        
        
        var uniqueTransactions: [String: Transaction] = [:]
        var duplicateIds: [Int] = []
        
        for transaction in allTransactions {
            let key = "\(transaction.amount)_\(transaction.transactionDate.timeIntervalSince1970)_\(transaction.categoryId)"
            
            if let existing = uniqueTransactions[key] {
                
                if transaction.id < existing.id {
                    duplicateIds.append(existing.id)
                    uniqueTransactions[key] = transaction
                } else {
                    duplicateIds.append(transaction.id)
                }
            } else {
                uniqueTransactions[key] = transaction
            }
        }
        
        if !duplicateIds.isEmpty {
            print("Removing \(duplicateIds.count) duplicate transactions: \(duplicateIds)")
            try await persistence.deleteTransactions(by: duplicateIds)
            print("Duplicates removed successfully!")
        } else {
            print("No duplicates found")
        }
        #endif
    }
} 
