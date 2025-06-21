import Foundation

protocol TransactionsListViewModelFactoryProtocol {
    @MainActor func makeTransactionsListViewModel(for direction: Direction) -> TransactionsListViewModel
}

final class TransactionsListViewModelFactory: TransactionsListViewModelFactoryProtocol {
    private let dependencyInjector: any DependencyInjectorProtocol
    
    init(dependencyInjector: any DependencyInjectorProtocol) {
        self.dependencyInjector = dependencyInjector
    }
    
    @MainActor func makeTransactionsListViewModel(for direction: Direction) -> TransactionsListViewModel {
        TransactionsListViewModel(
            direction: direction,
            repository: dependencyInjector.makeTransactionsRepository()
        )
    }
} 