import Foundation

protocol TransactionsListViewModelFactoryProtocol {
    @MainActor func makeTransactionsListViewModel(for direction: Category.Direction) -> TransactionsListViewModel
}

struct TransactionsListViewModelFactory: TransactionsListViewModelFactoryProtocol {
    unowned let di: DIContainer

    @MainActor func makeTransactionsListViewModel(for direction: Category.Direction) -> TransactionsListViewModel {
        TransactionsListViewModel(
            direction: direction,
            repository: di.transactionsRepository
        )
    }
} 
