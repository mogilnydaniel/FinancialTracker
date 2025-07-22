import Foundation
import SwiftData

@Model
final class BankAccountEntity {
    
    @Attribute(.unique) var id: Int
    var userId: Int
    var name: String
    var balanceString: String
    var currencyCode: String
    var creationDate: Date
    var modificationDate: Date

    init(
        id: Int,
        userId: Int,
        name: String,
        balance: Decimal,
        currency: BankAccount.Currency,
        creationDate: Date,
        modificationDate: Date
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.balanceString = balance.description
        self.currencyCode = currency.code
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
    
    convenience init(from bankAccount: BankAccount) {
        self.init(
            id: bankAccount.id,
            userId: bankAccount.userId,
            name: bankAccount.name,
            balance: bankAccount.balance,
            currency: bankAccount.currency,
            creationDate: bankAccount.creationDate,
            modificationDate: bankAccount.modificationDate
        )
    }

    func toDomainModel() -> BankAccount {
        BankAccount(
            id: id,
            userId: userId,
            name: name,
            balance: Decimal(string: balanceString) ?? 0,
            currency: BankAccount.Currency(code: currencyCode),
            creationDate: creationDate,
            modificationDate: modificationDate
        )
    }
    
    func toDomain() -> BankAccount {
        return toDomainModel()
    }

    static func fromDomain(_ account: BankAccount) -> BankAccountEntity {
        return BankAccountEntity(from: account)
    }

    func update(from bankAccount: BankAccount) {
        self.userId = bankAccount.userId
        self.name = bankAccount.name
        self.balanceString = bankAccount.balance.description
        self.currencyCode = bankAccount.currency.code
        self.modificationDate = bankAccount.modificationDate
    }
}

extension Array where Element == BankAccountEntity {
    
    func toDomainModels() -> [BankAccount] {
        map { $0.toDomainModel() }
    }
}

extension Array where Element == BankAccount {

    func toEntities() -> [BankAccountEntity] {
        map { BankAccountEntity(from: $0) }
    }
} 
