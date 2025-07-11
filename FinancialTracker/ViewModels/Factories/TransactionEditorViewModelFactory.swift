import Foundation

@MainActor
protocol TransactionEditorViewModelFactoryProtocol {
    func makeTransactionEditorViewModel(
        for mode: TransactionEditorViewModel.Mode
    ) -> TransactionEditorViewModel
}

struct TransactionEditorViewModelFactory: TransactionEditorViewModelFactoryProtocol {
    unowned let di: DIContainer

    func makeTransactionEditorViewModel(
        for mode: TransactionEditorViewModel.Mode
    ) -> TransactionEditorViewModel {
        TransactionEditorViewModel(
            mode: mode,
            repository: di.transactionsRepository,
            categoriesService: di.categoriesService,
            bankAccountsService: di.bankAccountsService
        )
    }
} 