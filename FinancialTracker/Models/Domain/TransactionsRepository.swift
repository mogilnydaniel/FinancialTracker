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

        #if DEBUG
        print("Fetching \(direction) transactions from \(normalizedStart) to \(normalizedEnd)")
        let startTime = Date()
        #endif

        async let fetchedTransactions = transactionsService.getTransactions(
            from: normalizedStart,
            to: normalizedEnd,
            direction: direction
        )
        
        async let fetchedCategories = categoriesService.getCategories(direction: direction)
        
        let (allTransactions, categories) = try await (fetchedTransactions, fetchedCategories)
        
        #if DEBUG
        let fetchTime = Date().timeIntervalSince(startTime)
        print("Fetched \(allTransactions.count) transactions and \(categories.count) categories in \(String(format: "%.2f", fetchTime))s")
        #endif
        
        let categoriesDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        
        let transactions: [Transaction] = allTransactions.compactMap { transaction in
            guard let category = categoriesDict[transaction.categoryId] else { return nil }
            guard category.direction == direction else { return nil }
            
            
            let adjustedAmount = category.direction == .outcome ? -transaction.amount : transaction.amount
            
            return Transaction(
                id: transaction.id,
                accountId: transaction.accountId,
                categoryId: transaction.categoryId,
                amount: adjustedAmount,
                transactionDate: transaction.transactionDate,
                comment: transaction.comment,
                creationDate: transaction.creationDate,
                modificationDate: transaction.modificationDate
            )
        }
        
        let totalAmount = transactions.reduce(Decimal.zero) { $0 + $1.amount }
        
        #if DEBUG
        print("Filtered to \(transactions.count) \(direction) transactions, total: \(totalAmount)")
        #endif
        
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
