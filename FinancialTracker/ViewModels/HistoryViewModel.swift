import Foundation
import SwiftUI
import Combine

@MainActor
final class HistoryViewModel: ObservableObject, TransactionsListProtocol, TransactionsFetcher {
    @Published var transactions: [Transaction] = []
    @Published var total: Decimal = .zero
    @Published var state: LoadingState = .idle
    @Published var categories: [Int: Category] = [:]
    
    var sort: TransactionSortOption = .date {
        didSet { loadTask?.cancel(); scheduleLoad() }
    }
    
    let direction: Category.Direction
    private let repository: any TransactionsRepositoryProtocol
    private var loadTask: Task<Void, Never>?
    
    @Published var startDate: Date = .oneMonthAgo {
        didSet { loadTask?.cancel(); scheduleLoad() }
    }
    
    @Published var endDate: Date = .today {
        didSet { loadTask?.cancel(); scheduleLoad() }
    }
    
    private var debounceTask: Task<Void, Never>?
    
    init(
        direction: Category.Direction,
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

    func load() async {
        state = .loading
        
        do {
            let result = try await fetchLatest()
            apply(result, to: self)
            state = .loaded
        } catch {
            state = .failed(error)
        }
    }
    
    func refresh() async {
        await load()
    }
    
    func sortTransactions(animated: Bool) {
        let sorted = sortedTransactions(transactions, by: sort)
        if transactions != sorted {
            if animated {
                withAnimation(.easeOut) { transactions = sorted }
            } else {
                transactions = sorted
            }
        }
    }
    
    func fetchLatest() async throws -> TransactionsSummary {
        try await repository.getTransactionsSummary(
            from: startDate,
            to: endDate,
            direction: direction
        )
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
            do {
                try await Task.sleep(for: .milliseconds(300))
                await load()
            } catch {
            }
        }
    }
} 


