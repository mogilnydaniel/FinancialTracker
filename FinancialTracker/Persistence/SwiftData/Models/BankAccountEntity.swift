import Foundation
import SwiftData

@Model
final class BankAccountEntity {
    
    @Attribute(.unique) var id: Int
    var userId: Int
    var name: String
    
    private var balanceString: String
    
    private var currencyCode: String
    
    var creationDate: Date
    var modificationDate: Date
    
    var balance: Decimal {
        get {
            return Decimal(string: balanceString) ?? 0
        }
        set {
            balanceString = newValue.description
        }
    }
    
    var currency: BankAccount.Currency {
        get {
            return BankAccount.Currency(code: currencyCode)
        }
        set {
            currencyCode = newValue.code
        }
    }

    
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
            balance: balance,
            currency: currency,
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
        self.balance = bankAccount.balance
        self.currency = bankAccount.currency
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
