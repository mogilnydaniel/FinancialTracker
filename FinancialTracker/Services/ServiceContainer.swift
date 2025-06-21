import Foundation

protocol DependencyInjectorProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T

    func makeCategoriesService() -> any CategoriesServiceProtocol
    func makeBankAccountsService() -> any BankAccountsServiceProtocol
    func makeTransactionsService() -> any TransactionsServiceProtocol
    func makeTransactionsRepository() -> any TransactionsRepositoryProtocol
    func makeTransactionsListViewModelFactory() -> TransactionsListViewModelFactoryProtocol
    func makeHistoryViewModelFactory() -> HistoryViewModelFactoryProtocol
}

final class DependencyInjector: DependencyInjectorProtocol {
    static let shared = DependencyInjector()
    
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    
    private init() {
        registerDefaultServices()
    }
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = {
            if let singleton = self.singletons[key] as? T {
                return singleton
            }
            let instance = factory()
            self.singletons[key] = instance
            return instance
        }
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let factory = factories[key] else {
            fatalError("No registration found for type \(type)")
        }
        return factory() as! T
    }
    
    private func registerDefaultServices() {
        registerSingleton((any CategoriesServiceProtocol).self) {
            MockCategoriesService()
        }
        
        registerSingleton((any BankAccountsServiceProtocol).self) {
            MockBankAccountsService()
        }
        
        registerSingleton((any TransactionsServiceProtocol).self) {
            MockTransactionsService()
        }
        
        registerSingleton((any TransactionsRepositoryProtocol).self) {
            TransactionsRepository(
                transactionsService: self.makeTransactionsService(),
                categoriesService: self.makeCategoriesService()
            )
        }
        
        register(TransactionsListViewModelFactoryProtocol.self) {
            TransactionsListViewModelFactory(dependencyInjector: self)
        }
        
        register(HistoryViewModelFactoryProtocol.self) {
            HistoryViewModelFactory(dependencyInjector: self)
        }
    }
}

extension DependencyInjector {
    func makeCategoriesService() -> any CategoriesServiceProtocol {
        resolve((any CategoriesServiceProtocol).self)
    }
    
    func makeBankAccountsService() -> any BankAccountsServiceProtocol {
        resolve((any BankAccountsServiceProtocol).self)
    }
    
    func makeTransactionsService() -> any TransactionsServiceProtocol {
        resolve((any TransactionsServiceProtocol).self)
    }
    
    func makeTransactionsRepository() -> any TransactionsRepositoryProtocol {
        resolve((any TransactionsRepositoryProtocol).self)
    }
    
    func makeTransactionsListViewModelFactory() -> TransactionsListViewModelFactoryProtocol {
        resolve(TransactionsListViewModelFactoryProtocol.self)
    }
    
    func makeHistoryViewModelFactory() -> HistoryViewModelFactoryProtocol {
        resolve(HistoryViewModelFactoryProtocol.self)
    }
} 
