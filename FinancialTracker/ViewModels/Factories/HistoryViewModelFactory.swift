import Foundation

protocol HistoryViewModelFactoryProtocol {
    @MainActor func makeHistoryViewModel(for direction: Direction) -> HistoryViewModel
}

final class HistoryViewModelFactory: HistoryViewModelFactoryProtocol {
    private let dependencyInjector: any DependencyInjectorProtocol
    
    init(dependencyInjector: any DependencyInjectorProtocol) {
        self.dependencyInjector = dependencyInjector
    }
    
    @MainActor func makeHistoryViewModel(for direction: Direction) -> HistoryViewModel {
        HistoryViewModel(
            direction: direction,
            repository: dependencyInjector.makeTransactionsRepository()
        )
    }
} 