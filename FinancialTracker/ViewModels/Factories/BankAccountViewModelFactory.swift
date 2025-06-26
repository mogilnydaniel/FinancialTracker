import Foundation

protocol BankAccountViewModelFactoryProtocol {
    func makeBankAccountViewModel() -> BankAccountViewModel
}

struct BankAccountViewModelFactory: BankAccountViewModelFactoryProtocol {
    unowned let di: DIContainer

    func makeBankAccountViewModel() -> BankAccountViewModel {
        BankAccountViewModel(service: di.bankAccountsService)
    }
} 