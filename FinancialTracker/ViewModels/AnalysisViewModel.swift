import Foundation
import Combine

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published private(set) var state: LoadingState = .idle
    @Published var startDate: Date = .oneMonthAgo
    @Published var endDate: Date = .today
    @Published private(set) var operations: [AnalysisOperationItem] = []
    @Published private(set) var total: Decimal = .zero
    @Published var sortOption: TransactionSortOption = .date
    
    let direction: Category.Direction
    private let repository: any TransactionsRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: any TransactionsRepositoryProtocol, direction: Category.Direction) {
        self.repository = repository
        self.direction = direction
        
        Publishers.CombineLatest3($startDate, $endDate, $sortOption)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.load()
            }
            .store(in: &cancellables)

        $startDate
            .removeDuplicates()
            .sink { [weak self] date in
                guard let self = self else { return }
                if date > self.endDate {
                    self.endDate = date
                }
            }
            .store(in: &cancellables)

        $endDate
            .removeDuplicates()
            .sink { [weak self] date in
                guard let self = self else { return }
                if date < self.startDate {
                    self.startDate = date
                }
            }
            .store(in: &cancellables)
    }
    
    func load() {
        state = .loading
        
        Task {
            do {
                let summary = try await repository.getTransactionsSummary(
                    from: startDate,
                    to: endDate,
                    direction: direction
                )
                process(summary: summary)
                state = .loaded
            } catch {
                state = .failed(ErrorMapper.wrap(error))
            }
        }
    }
    
    private func process(summary: TransactionsSummary) {
        self.total = summary.total
        
        let groupedByCategory = Dictionary(grouping: summary.transactions, by: { $0.categoryId })
        let grandTotal = summary.transactions.reduce(0) { $0 + abs($1.amount) }

        guard grandTotal > 0 else {
            self.operations = []
            return
        }
        
        let analysisItems = groupedByCategory.compactMap { (categoryId, transactions) -> AnalysisOperationItem? in
            guard let category = summary.categories[categoryId] else { return nil }
            
            let categoryTotal = transactions.reduce(0) { $0 + abs($1.amount) }
            let percentage = (categoryTotal / grandTotal * 100).doubleValue
            
            return AnalysisOperationItem(
                category: category,
                totalAmount: categoryTotal,
                percentage: percentage,
                comment: transactions.first?.comment
            )
        }
        
        self.operations = sort(items: analysisItems)
    }

    private func sort(items: [AnalysisOperationItem]) -> [AnalysisOperationItem] {
        switch sortOption {
        case .date:
            return items.sorted { $0.category.name < $1.category.name }
        case .amount:
            return items.sorted { $0.totalAmount > $1.totalAmount }
        }
    }
}

extension Decimal {
    var doubleValue: Double {
        return NSDecimalNumber(decimal: self).doubleValue
    }
} 
