import Foundation

protocol BankAccountsServiceProtocol {
    func getBankAccount() async throws -> BankAccount
    func updateBankAccount(_ updatedAccount: BankAccount) async throws -> BankAccount
}


