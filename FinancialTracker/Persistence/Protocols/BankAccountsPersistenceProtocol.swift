import Foundation

protocol BankAccountsPersistenceProtocol: Sendable {
    func getBankAccount() async throws -> BankAccount?
    func saveBankAccount(_ account: BankAccount) async throws -> BankAccount
    func deleteBankAccount() async throws
    func accountExists() async throws -> Bool
} 