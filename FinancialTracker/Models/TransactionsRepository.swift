import Foundation

protocol TransactionsRepositoryProtocol {
    func getTransactionsSummary(
        from startDate: Date,
        to endDate: Date,
        direction: Direction
    ) async throws -> TransactionsSummary
    
    func createTransaction(_ request: TransactionRequest) async throws -> Transaction
    func updateTransaction(id: Int, with request: TransactionRequest) async throws -> Transaction
    func deleteTransaction(withId id: Int) async throws -> Transaction
}

struct TransactionsSummary {
    let transactions: [Transaction]
    let categories: [Int: Category]
    let total: Decimal
}

final class TransactionsRepository: TransactionsRepositoryProtocol {
    private let transactionsService: any TransactionsServiceProtocol
    private let categoriesService: any CategoriesServiceProtocol
    
    init(
        transactionsService: any TransactionsServiceProtocol,
        categoriesService: any CategoriesServiceProtocol
    ) {
        self.transactionsService = transactionsService
        self.categoriesService = categoriesService
    }
    
    func getTransactionsSummary(
        from startDate: Date,
        to endDate: Date,
        direction: Direction
    ) async throws -> TransactionsSummary {
        async let fetchedTransactions = transactionsService.getTransactions(
            from: startDate,
            to: endDate,
            direction: direction
        )
        
        async let fetchedCategories = categoriesService.getCategories()
        
        let (transactions, categories) = try await (fetchedTransactions, fetchedCategories)
        
        let categoriesDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let totalAmount = transactions.reduce(Decimal.zero) { $0 + $1.amount }
        
        return TransactionsSummary(
            transactions: transactions,
            categories: categoriesDict,
            total: totalAmount
        )
    }
    
    func createTransaction(_ request: TransactionRequest) async throws -> Transaction {
        return try await transactionsService.createTransaction(request)
    }
    
    func updateTransaction(id: Int, with request: TransactionRequest) async throws -> Transaction {
        return try await transactionsService.updateTransaction(id: id, with: request)
    }
    
    func deleteTransaction(withId id: Int) async throws -> Transaction {
        return try await transactionsService.deleteTransaction(withId: id)
    }
} 