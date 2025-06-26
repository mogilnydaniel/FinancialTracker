import Foundation

protocol BankAccountsServiceProtocol {
    func getBankAccount() async throws -> BankAccount
    func updateBankAccount(_ updatedAccount: BankAccount) async throws -> BankAccount
}

actor MockBankAccountsService: BankAccountsServiceProtocol {
    private var account: BankAccount
    
    init() {
        account = BankAccount(
            id: 1,
            userId: 1,
            name: "Основной счет",
            balance: 150000.50,
            currency: .rub,
            creationDate: Date(),
            modificationDate: Date()
        )
    }

    func getBankAccount() async throws -> BankAccount {
        try await Task.sleep(for: .seconds(0.5))
        return account
    }
    
    func updateBankAccount(_ updatedAccount: BankAccount) async throws -> BankAccount {
        try await Task.sleep(for: .seconds(0.5))
        account = updatedAccount
        return account
    }
}
