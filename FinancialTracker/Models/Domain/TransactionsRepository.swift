import Foundation

protocol TransactionsRepositoryProtocol {
    func getTransactionsSummary(
        from startDate: Date,
        to endDate: Date,
        direction: Category.Direction
    ) async throws -> TransactionsSummary
    
    @discardableResult
    func createTransaction(_ request: TransactionRequest) async throws -> Transaction
    
    @discardableResult
    func updateTransaction(id: Int, with request: TransactionRequest) async throws -> Transaction
    
    @discardableResult
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
        direction: Category.Direction
    ) async throws -> TransactionsSummary {
        let normalizedStart = startDate.startOfDay
        let normalizedEnd = endDate.endOfDay

        async let fetchedTransactions = transactionsService.getTransactions(
            from: normalizedStart,
            to: normalizedEnd,
            direction: direction
        )
        
        async let fetchedCategories = categoriesService.getCategories()
        
        let (allTransactions, categories) = try await (fetchedTransactions, fetchedCategories)
        
        let categoriesDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        
        let transactions = allTransactions.filter { transaction in
            guard let category = categoriesDict[transaction.categoryId] else { return false }
            return category.direction == direction
        }
        
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
