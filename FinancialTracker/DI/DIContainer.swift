import Foundation
import SwiftUI

final class DIContainer {
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

    init(
        categoriesService: any CategoriesServiceProtocol,
        bankAccountsService: any BankAccountsServiceProtocol,
        transactionsService: any TransactionsServiceProtocol
    ) {
        self.categoriesService = categoriesService
        self.bankAccountsService = bankAccountsService
        self.transactionsService = transactionsService
    }

    static let production: DIContainer = {
        DIContainer(
            categoriesService: MockCategoriesService(),
            bankAccountsService: MockBankAccountsService(),
            transactionsService: MockTransactionsService()
        )
    }()
}

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = .production
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
} 
