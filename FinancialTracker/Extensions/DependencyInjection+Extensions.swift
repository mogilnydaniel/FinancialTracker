import SwiftUI

private struct ViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any TransactionsListViewModelFactoryProtocol = {
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        return DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        ).transactionsListVMFactory
    }()
}

private struct HistoryViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any HistoryViewModelFactoryProtocol = {
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        return DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        ).historyVMFactory
    }()
}

private struct BankAccountViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any BankAccountViewModelFactoryProtocol = {
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        return DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        ).bankAccountVMFactory
    }()
}

private struct TransactionEditorViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any TransactionEditorViewModelFactoryProtocol = {
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        return DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        ).transactionEditorVMFactory
    }()
}

private struct AnalysisViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any AnalysisViewModelFactoryProtocol = {
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        return DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        ).analysisVMFactory
    }()
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