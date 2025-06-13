import Foundation

final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private init() {}
    
    private lazy var categoriesService: any CategoriesServiceProtocol = MockCategoriesService()
    func makeCategoriesService() -> any CategoriesServiceProtocol {
        categoriesService
    }
    
    private lazy var bankAccountService: any BankAccountsServiceProtocol = MockBankAccountsService()
    func makeBankAccountsService() -> any BankAccountsServiceProtocol {
        bankAccountService
    }
    
    private lazy var transactionsService: any TransactionsServiceProtocol = MockTransactionsService()
    func makeTransactionsService() -> any TransactionsServiceProtocol {
        transactionsService
    }
} 
