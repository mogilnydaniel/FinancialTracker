import Foundation

protocol TransactionsPersistenceProtocol {
    
    func getAllTransactions() async throws -> [Transaction]

    func getTransaction(by id: Int) async throws -> Transaction?

    func getTransactions(from startDate: Date, to endDate: Date) async throws -> [Transaction]

    @discardableResult
    func createTransaction(_ transaction: Transaction) async throws -> Transaction
    
    @discardableResult
    func updateTransaction(_ transaction: Transaction) async throws -> Transaction
    
    @discardableResult
    func deleteTransaction(by id: Int) async throws -> Transaction?
    
    func saveTransactions(_ transactions: [Transaction]) async throws

    func deleteTransactions(by ids: [Int]) async throws

    func clearAllTransactions() async throws

    func transactionsCount() async throws -> Int
    
    func transactionExists(id: Int) async throws -> Bool
    
    func getLatestTransaction() async throws -> Transaction?
    
    func syncTransactions(_ transactions: [Transaction]) async throws
} 
