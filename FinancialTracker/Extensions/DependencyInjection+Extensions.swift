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

private struct TransactionEditorViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any TransactionEditorViewModelFactoryProtocol = DIContainer.production.transactionEditorVMFactory
}

private struct AnalysisViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any AnalysisViewModelFactoryProtocol = DIContainer.production.analysisVMFactory
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
    
    var transactionEditorViewModelFactory: any TransactionEditorViewModelFactoryProtocol {
        get { di.transactionEditorVMFactory }
        set { self[TransactionEditorViewModelFactoryKey.self] = newValue }
    }

    var analysisViewModelFactory: any AnalysisViewModelFactoryProtocol {
        get { di.analysisVMFactory }
        set { self[AnalysisViewModelFactoryKey.self] = newValue }
    }
} 