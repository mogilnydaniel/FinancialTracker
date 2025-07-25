import Foundation
import SwiftUI

final class DIContainer {
    static let apiToken = "WNKoU01o5koxFvqP6882dwjR"
    
    let categoriesService: any CategoriesServiceProtocol
    let bankAccountsService: any BankAccountsServiceProtocol
    let transactionsService: any TransactionsServiceProtocol
    lazy var transactionsRepository: any TransactionsRepositoryProtocol = {
        TransactionsRepository(
            transactionsService: self.transactionsService,
            categoriesService: self.categoriesService
        )
    }()

    lazy var transactionsListVMFactory: any TransactionsListViewModelFactoryProtocol = {
        TransactionsListViewModelFactory(di: self)
    }()
    lazy var historyVMFactory: any HistoryViewModelFactoryProtocol = {
        HistoryViewModelFactory(di: self)
    }()
    lazy var bankAccountVMFactory: any BankAccountViewModelFactoryProtocol = {
        BankAccountViewModelFactory(di: self)
    }()

    lazy var transactionEditorVMFactory: any TransactionEditorViewModelFactoryProtocol = {
        TransactionEditorViewModelFactory(di: self)
    }()

    lazy var analysisVMFactory: any AnalysisViewModelFactoryProtocol = {
        AnalysisViewModelFactory(di: self)
    }()

    lazy var articlesVMFactory: any ArticlesViewModelFactoryProtocol = {
        ArticlesViewModelFactory(di: self)
    }()

    lazy var articlesService: any ArticlesServiceProtocol = {
        ArticlesService(categoriesService: self.categoriesService)
    }()

    init(
        categoriesService: any CategoriesServiceProtocol,
        bankAccountsService: any BankAccountsServiceProtocol,
        transactionsService: any TransactionsServiceProtocol
    ) {
        self.categoriesService = categoriesService
        self.bankAccountsService = bankAccountsService
        self.transactionsService = transactionsService
    }


}

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = {
        let client = NetworkClient(token: DIContainer.apiToken)
        return DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        )
    }()
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
} 
