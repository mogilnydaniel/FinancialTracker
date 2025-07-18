import Foundation

protocol TransactionsServiceProtocol {
    func getTransactions(
        from startDate: Date,
        to endDate: Date,
        direction: Category.Direction
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


