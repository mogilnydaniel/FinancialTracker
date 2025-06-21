import Foundation
import Combine
import SwiftUI

@Observable
final class HistoryViewModel: TransactionsListProtocol, TransactionsFetcher {
    var startDate: Date = .oneMonthAgo {
        didSet {
            if startDate > endDate {
                endDate = startDate
            }
            scheduleLoad()
        }
    }
    var endDate: Date = Date() {
        didSet {
            if endDate < startDate {
                startDate = endDate
            }
            scheduleLoad()
        }
    }
    var sort: TransactionSortOption = .date {
        didSet { sortTransactions(animated: true) }
    }
    
    var transactions: [Transaction] = []
    var total: Decimal = .zero
    var state: LoadingState = .idle
    var categories: [Int: Category] = [:]
    
    let direction: Direction
    private let repository: any TransactionsRepositoryProtocol
    private var loadTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    
    init(
        direction: Direction,
        repository: any TransactionsRepositoryProtocol
    ) {
        self.direction = direction
        self.repository = repository
        
        scheduleLoad()
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
        return try await repository.getTransactionsSummary(
            from: startDate.startOfDay,
            to: endDate.endOfDay,
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
    
    func resetToDefaults() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            startDate = .oneMonthAgo
            endDate = Date()
        }
    }
    
    var isDefaultPeriod: Bool {
        let calendar = Calendar.current
        let todayStart = Date().startOfDay
        let monthAgoStart = Date.oneMonthAgo.startOfDay
        
        return calendar.isDate(startDate.startOfDay, inSameDayAs: monthAgoStart) &&
               calendar.isDate(endDate.startOfDay, inSameDayAs: todayStart)
    }
    
    private func scheduleLoad() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled {
                await loadTransactions()
            }
        }
    }
    
    func loadTransactions() async {
        loadTask?.cancel()
        
        await MainActor.run { state = .loading }
        
        loadTask = Task {
            do {
                let result = try await fetchLatest()
                
                try Task.checkCancellation()
                
                await MainActor.run {
                    apply(result, to: self)
                    state = .loaded
                }
                
            } catch where !(error is CancellationError) {
                await MainActor.run {
                    self.transactions = []
                    self.categories = [:]
                    self.total = 0
                    self.state = .failed(error)
                }
            } catch {
            }
        }
        await loadTask?.value
    }
} 
