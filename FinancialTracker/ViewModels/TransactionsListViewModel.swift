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
    
    deinit {
    }
    
    func refresh() async {
        loadTask?.cancel()
        loadTask = Task {
            guard state != .loading else { return }
            
            #if DEBUG
            let startTime = Date()
            #endif
            
            let showLoading = (state != .loaded)
            if showLoading {
                state = .loading
            }
            do {
                let result = try await fetchLatest()
                guard !Task.isCancelled else { return }
                apply(result, to: self)
                if showLoading {
                    state = .loaded
                }
                
                #if DEBUG
                let elapsed = Date().timeIntervalSince(startTime)
                print("Loaded \(result.transactions.count) \(direction) transactions in \(String(format: "%.2f", elapsed))s")
                #endif
            } catch is CancellationError {
                return
            } catch {
                if showLoading {
                    state = .failed(ErrorMapper.wrap(error))
                } else {
                    errorMessage = ErrorMapper.message(for: error)
                }
                
                #if DEBUG
                print("Failed to load \(direction) transactions: \(error)")
                #endif
            }
        }
        await loadTask?.value
    }
    
    func loadInitialData() async {
        guard state == .idle else { return }
        await refresh()
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
        let today = Date.today
        let endDate = today.endOfDay
        let startDate = today.startOfDay
        
        #if DEBUG
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        print("fetchLatest for \(direction): from \(formatter.string(from: startDate)) to \(formatter.string(from: endDate))")
        #endif
        
        return try await repository.getTransactionsSummary(
            from: startDate,
            to: endDate,
            direction: direction
        )
    }
}
