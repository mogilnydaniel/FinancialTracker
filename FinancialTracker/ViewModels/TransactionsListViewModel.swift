import Foundation
import SwiftUI
import Combine

@MainActor
final class TransactionsListViewModel: ObservableObject, TransactionsListProtocol, TransactionsFetcher {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Int: Category] = [:]
    @Published var total: Decimal = .zero
    @Published var state: LoadingState = .idle
    
    var errorMessage: String?
    
    var isLoaded: Bool {
        if case .loaded = state {
            return true
        }
        return false
    }

    var sort: TransactionSortOption = .date {
        didSet { sortTransactions(animated: true) }
    }
    
    let direction: Category.Direction
    private let repository: any TransactionsRepositoryProtocol
    private var loadTask: Task<Void, Never>?

    init(
        direction: Category.Direction,
        repository: any TransactionsRepositoryProtocol
    ) {
        self.direction = direction
        self.repository = repository
    }
    
    func refresh() async {
        guard state != .loading else { return }
        
        let showLoading = (state != .loaded)
        if showLoading {
            state = .loading
        }
        do {
            let result = try await fetchLatest()
            apply(result, to: self)
            if showLoading {
                state = .loaded
            }
        } catch {
            if showLoading {
                state = .failed(error)
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func loadInitialData() async {
        if state == .idle {
            await refresh()
        }
    }
    
    func refreshTrigger() {
        Task {
            await refresh()
        }
    }

    func sortTransactions(animated: Bool) {
        let sorted = sortedTransactions(transactions, by: sort)
        
        if animated {
            withAnimation(.spring) {
                transactions = sorted
            }
        } else {
            transactions = sorted
        }
    }
    
    func fetchLatest() async throws -> TransactionsSummary {
        try await repository.getTransactionsSummary(
            from: Date.today.startOfDay,
            to: Date.today.endOfDay,
            direction: direction
        )
    }
}
