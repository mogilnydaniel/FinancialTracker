import Foundation
import SwiftUI

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case failed(Error)
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded):
            return true
        case let (.failed(lError), .failed(rError)):
            return lError.localizedDescription == rError.localizedDescription
        default:
            return false
        }
    }
}

enum TransactionSortOption: String, CaseIterable, Identifiable {
    case date = "По дате"
    case amount = "По сумме"
    var id: Self { self }
}

protocol TransactionsFetcher {
    func fetchLatest() async throws -> TransactionsSummary
}

extension TransactionsFetcher {
    @MainActor
    func apply(_ summary: TransactionsSummary, to viewModel: any TransactionsListProtocol) {
        viewModel.transactions = summary.transactions
        viewModel.categories = summary.categories
        viewModel.total = summary.total
        viewModel.sortTransactions(animated: false)
    }
    
    func sortedTransactions(_ transactions: [Transaction], by sort: TransactionSortOption) -> [Transaction] {
        switch sort {
        case .date:
            return transactions.sorted { first, second in
                if first.transactionDate == second.transactionDate {
                    return first.id > second.id
                }
                return first.transactionDate > second.transactionDate
            }
        case .amount:
            return transactions.sorted { first, second in
                if first.amount.magnitude == second.amount.magnitude {
                    return first.id > second.id
                }
                return first.amount.magnitude > second.amount.magnitude
            }
        }
    }
}

@MainActor
protocol TransactionsListProtocol: AnyObject {
    var transactions: [Transaction] { get set }
    var categories: [Int: Category] { get set }
    var total: Decimal { get set }
    var sort: TransactionSortOption { get set }
    
    func sortTransactions(animated: Bool)
} 
