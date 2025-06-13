import Foundation

protocol TransactionsServiceProtocol {
    associatedtype TransactionRequest
    
    func getTransactions(from startDate: Date, to endDate: Date) async throws -> [Transaction]
    
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
    
    struct TransactionRequest {
        let accountId: Int
        let categoryId: Int
        let amount: Decimal
        let transactionDate: Date
        let comment: String?
    }

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
    
    private var transactions: [Int: Transaction] = {
        let calendar = Calendar.current
        let now = Date()
        return [
            1: Transaction(
                id: 1,
                accountId: 1,
                categoryId: 1,
                amount: 75000.00,
                transactionDate: calendar.date(byAdding: .day, value: -5, to: now)!,
                comment: "Зарплата за июнь",
                creationDate: now,
                modificationDate: now
            ),
            2: Transaction(
                id: 2,
                accountId: 1,
                categoryId: 3,
                amount: -2500.50,
                transactionDate: calendar.date(byAdding: .day, value: -3, to: now)!,
                comment: "Продукты в супермаркете",
                creationDate: now,
                modificationDate: now
            ),
            3: Transaction(
                id: 3,
                accountId: 1,
                categoryId: 4,
                amount: -450.00,
                transactionDate: calendar.date(byAdding: .day, value: -2, to: now)!,
                comment: "Метро",
                creationDate: now,
                modificationDate: now
            ),
            4: Transaction(
                id: 4,
                accountId: 1,
                categoryId: 5,
                amount: -1200.00,
                transactionDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                comment: "Кино",
                creationDate: now,
                modificationDate: now
            )
        ]
    }()

    private var nextId: Int {
        (transactions.keys.max() ?? 0) + 1
    }

    func getTransactions(from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        try await Task.sleep(for: .seconds(0.5))
        let filtered = transactions.values.filter { transaction in
            let transactionDate = transaction.transactionDate
            return transactionDate >= startDate && transactionDate <= endDate
        }
        return Array(filtered)
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
