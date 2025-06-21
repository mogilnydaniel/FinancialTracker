import Foundation

protocol TransactionsServiceProtocol {
    func getTransactions(
        from startDate: Date,
        to endDate: Date,
        direction: Direction
    ) async throws -> [Transaction]
    
    @discardableResult
    func createTransaction(
        _ request: TransactionRequest
    ) async throws -> Transaction
    
    @discardableResult
    func updateTransaction(
        id: Int,
        with request: TransactionRequest
    ) async throws -> Transaction
    
    @discardableResult
    func deleteTransaction(withId id: Int) async throws -> Transaction
}

actor MockTransactionsService: TransactionsServiceProtocol {
    enum TransactionError: LocalizedError {
        case notFound
        case invalidAmount
        case invalidDate
        case networkError
        
        var errorDescription: String? {
            switch self {
            case .notFound:
                return "Transaction not found"
            case .invalidAmount:
                return "Invalid transaction amount"
            case .invalidDate:
                return "Invalid transaction date"
            case .networkError:
                return "Network error occurred"
            }
        }
    }
    
    private var transactions: [Int: Transaction] = MockTransactionsData.generateMockTransactions()


    private var nextId: Int {
        (transactions.keys.max() ?? 0) + 1
    }

    func getTransactions(
        from startDate: Date,
        to endDate: Date,
        direction: Direction
    ) async throws -> [Transaction] {
        let dateFiltered = transactions.values.filter { transaction in
            let transactionDate = transaction.transactionDate
            return transactionDate >= startDate && transactionDate <= endDate
        }
        
        let directionFiltered = dateFiltered.filter { transaction in
            switch direction {
            case .income:
                return transaction.amount > 0
            case .outcome:
                return transaction.amount < 0
            }
        }
        
        return Array(directionFiltered)
    }

    func createTransaction(_ request: TransactionRequest) async throws -> Transaction {
        try await Task.sleep(for: .seconds(0.3))
        let newId = nextId
        let newTransaction = Transaction(
            id: newId,
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: request.amount,
            transactionDate: request.transactionDate,
            comment: request.comment,
            creationDate: Date(),
            modificationDate: Date()
        )
        transactions[newId] = newTransaction
        return newTransaction
    }

    func updateTransaction(id: Int, with request: TransactionRequest) async throws -> Transaction {
        try await Task.sleep(for: .seconds(0.3))
        guard let oldTransaction = transactions[id] else {
            throw TransactionError.notFound
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
        transactions[id] = updatedTransaction
        return updatedTransaction
    }
 
    func deleteTransaction(withId id: Int) async throws -> Transaction {
        try await Task.sleep(for: .seconds(0.2))
        guard let removedTransaction = transactions.removeValue(forKey: id) else {
            throw TransactionError.notFound
        }
        return removedTransaction
    }
}
