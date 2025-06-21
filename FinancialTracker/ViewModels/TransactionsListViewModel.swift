import Foundation
import SwiftUI

@Observable
final class TransactionsListViewModel: TransactionsListProtocol, TransactionsFetcher {
    var transactions: [Transaction] = []
    var total: Decimal = .zero
    var state: LoadingState = .idle
    var categories: [Int: Category] = [:]
    var sort: TransactionSortOption = .date {
        didSet { sortTransactions(animated: true) }
    }
    
    let direction: Direction
    private let repository: any TransactionsRepositoryProtocol

    init(
        direction: Direction,
        repository: any TransactionsRepositoryProtocol
    ) {
        self.direction = direction
        self.repository = repository
    }
    
    var isLoaded: Bool {
        if case .loaded = state { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .failed(let error) = state {
            return error.localizedDescription
        }
        return nil
    }

    func loadInitialData() async {
        guard state == .idle else { return }
        await MainActor.run { state = .loading }
        do {
            let result = try await fetchLatest()
            await MainActor.run {
                apply(result, to: self)
                state = .loaded
            }
        } catch {
            await MainActor.run { state = .failed(error) }
        }
    }

    func refresh() async {
        do {
            let result = try await fetchLatest()
            
            try await Task.sleep(for: .seconds(0.3))
            
            await MainActor.run {
                apply(result, to: self)
                state = .loaded
            }
        } catch {
            await MainActor.run { state = .failed(error) }
        }
    }

    func fetchLatest() async throws -> TransactionsSummary {
        let today = Date()
        
        return try await repository.getTransactionsSummary(
            from: today.startOfDay,
            to: today.endOfDay,
            direction: direction
        )
    }

    func sortTransactions(animated: Bool = false) {
        let sorted = sortedTransactions(transactions, by: sort)
        
        if transactions != sorted {
            if animated {
                withAnimation(.easeInOut(duration: 0.4)) {
                    transactions = sorted
                }
            } else {
                transactions = sorted
            }
        }
    }

    func refreshTrigger() {
        Task {
            await refresh()
        }
    }
}
