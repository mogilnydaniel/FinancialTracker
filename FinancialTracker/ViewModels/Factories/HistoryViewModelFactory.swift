import Foundation

protocol HistoryViewModelFactoryProtocol {
    @MainActor func makeHistoryViewModel(for direction: Direction) -> HistoryViewModel
}

struct HistoryViewModelFactory: HistoryViewModelFactoryProtocol {
    unowned let di: DIContainer
    
    @MainActor func makeHistoryViewModel(for direction: Direction) -> HistoryViewModel {
        HistoryViewModel(
            direction: direction,
            repository: di.transactionsRepository
        )
    }
} 