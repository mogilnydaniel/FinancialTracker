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
        MockArticlesService(categoriesService: self.categoriesService)
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

    static let network: DIContainer = {
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        return DIContainer(
            categoriesService: NetworkCategoriesService(client: client),
            bankAccountsService: NetworkAccountsService(client: client),
            transactionsService: NetworkTransactionsService(client: client)
        )
    }()
    
    static let hybrid: DIContainer = {
        let token = "WNKoU01o5koxFvqP6882dwjR"
        let client = NetworkClient(token: token)
        let manager = SwiftDataManager.shared
        
        do {
            let transactionsPersistence = try manager.createTransactionsPersistence()
            let bankAccountsPersistence = try manager.createBankAccountsPersistence()
            let categoriesPersistence = try manager.createCategoriesPersistence()
            let backup = try manager.createBackupPersistence()
            
            let backupSyncService = BackupSyncService(
                backup: backup,
                networkClient: client,
                transactionsPersistence: transactionsPersistence,
                bankAccountsPersistence: bankAccountsPersistence
            )
            
            return DIContainer(
                categoriesService: HybridCategoriesService(
                    persistence: categoriesPersistence,
                    networkClient: client
                ),
                bankAccountsService: HybridBankAccountsService(
                    persistence: bankAccountsPersistence,
                    backup: backup,
                    networkClient: client,
                    syncService: backupSyncService
                ),
                transactionsService: HybridTransactionsService(
                    persistence: transactionsPersistence,
                    backup: backup,
                    networkClient: client,
                    syncService: backupSyncService
                )
            )
        } catch {
            fatalError("Failed to create hybrid DIContainer: \(error)")
        }
    }()
}

private struct DIContainerKey: EnvironmentKey {
    static let defaultValue: DIContainer = .network
}

extension EnvironmentValues {
    var di: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
} 
