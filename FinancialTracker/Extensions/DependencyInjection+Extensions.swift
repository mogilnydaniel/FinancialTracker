import SwiftUI

private struct ViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any TransactionsListViewModelFactoryProtocol = DIContainer.production.transactionsListVMFactory
}

private struct HistoryViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any HistoryViewModelFactoryProtocol = DIContainer.production.historyVMFactory
}

private struct BankAccountViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any BankAccountViewModelFactoryProtocol = DIContainer.production.bankAccountVMFactory
}

extension EnvironmentValues {
    var viewModelFactory: any TransactionsListViewModelFactoryProtocol {
        get { di.transactionsListVMFactory }
        set { self[ViewModelFactoryKey.self] = newValue }
    }
    
    var historyViewModelFactory: any HistoryViewModelFactoryProtocol {
        get { di.historyVMFactory }
        set { self[HistoryViewModelFactoryKey.self] = newValue }
    }
    
    var bankAccountViewModelFactory: any BankAccountViewModelFactoryProtocol {
        get { di.bankAccountVMFactory }
        set { self[BankAccountViewModelFactoryKey.self] = newValue }
    }
} 