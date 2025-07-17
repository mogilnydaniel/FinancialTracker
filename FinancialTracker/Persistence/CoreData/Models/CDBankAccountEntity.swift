import Foundation
import CoreData

@objc(CDBankAccountEntity)
public class CDBankAccountEntity: NSManagedObject {
    
    var balance: Decimal {
        get {
            return Decimal(string: balanceString ?? "0") ?? 0
        }
        set {
            balanceString = newValue.description
        }
    }
    
    var currency: BankAccount.Currency {
        get {
            return BankAccount.Currency(code: currencyCode ?? "RUB")
        }
        set {
            currencyCode = newValue.code
        }
    }
    
    convenience init(context: NSManagedObjectContext, from bankAccount: BankAccount) {
        self.init(context: context)
        self.id = Int32(bankAccount.id)
        self.userId = Int32(bankAccount.userId)
        self.name = bankAccount.name
        self.balance = bankAccount.balance
        self.currency = bankAccount.currency
        self.creationDate = bankAccount.creationDate
        self.modificationDate = bankAccount.modificationDate
    }
    
    func toDomainModel() -> BankAccount {
        BankAccount(
            id: Int(id),
            userId: Int(userId),
            name: name ?? "",
            balance: balance,
            currency: currency,
            creationDate: creationDate ?? Date(),
            modificationDate: modificationDate ?? Date()
        )
    }
    
    func update(from bankAccount: BankAccount) {
        self.userId = Int32(bankAccount.userId)
        self.name = bankAccount.name
        self.balance = bankAccount.balance
        self.currency = bankAccount.currency
        self.modificationDate = bankAccount.modificationDate
    }
}

extension CDBankAccountEntity {
    
    @NSManaged public var id: Int32
    @NSManaged public var userId: Int32
    @NSManaged public var name: String?
    @NSManaged public var balanceString: String?
    @NSManaged public var currencyCode: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var modificationDate: Date?
}

extension CDBankAccountEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBankAccountEntity> {
        return NSFetchRequest<CDBankAccountEntity>(entityName: "CDBankAccountEntity")
    }
}

extension Array where Element == CDBankAccountEntity {
    
    func toDomainModels() -> [BankAccount] {
        map { $0.toDomainModel() }
    }
}

extension Array where Element == BankAccount {
    
    func toCoreDataEntities(context: NSManagedObjectContext) -> [CDBankAccountEntity] {
        map { CDBankAccountEntity(context: context, from: $0) }
    }
} 