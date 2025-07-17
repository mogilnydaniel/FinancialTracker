import Foundation
import CoreData

@objc(CDTransactionEntity)
public class CDTransactionEntity: NSManagedObject {
    
    var amount: Decimal {
        get {
            return Decimal(string: amountString ?? "0") ?? 0
        }
        set {
            amountString = newValue.description
        }
    }
    
    convenience init(context: NSManagedObjectContext, from transaction: Transaction) {
        self.init(context: context)
        self.id = Int32(transaction.id)
        self.accountId = Int32(transaction.accountId)
        self.categoryId = Int32(transaction.categoryId)
        self.amount = transaction.amount
        self.transactionDate = transaction.transactionDate
        self.comment = transaction.comment
        self.creationDate = transaction.creationDate
        self.modificationDate = transaction.modificationDate
    }
    
    func toDomainModel() -> Transaction {
        Transaction(
            id: Int(id),
            accountId: Int(accountId),
            categoryId: Int(categoryId),
            amount: amount,
            transactionDate: transactionDate ?? Date(),
            comment: comment,
            creationDate: creationDate ?? Date(),
            modificationDate: modificationDate ?? Date()
        )
    }
    
    func update(from transaction: Transaction) {
        self.accountId = Int32(transaction.accountId)
        self.categoryId = Int32(transaction.categoryId)
        self.amount = transaction.amount
        self.transactionDate = transaction.transactionDate
        self.comment = transaction.comment
        self.modificationDate = transaction.modificationDate
    }
}

extension CDTransactionEntity {
    
    @NSManaged public var id: Int32
    @NSManaged public var accountId: Int32
    @NSManaged public var categoryId: Int32
    @NSManaged public var amountString: String?
    @NSManaged public var transactionDate: Date?
    @NSManaged public var comment: String?
    @NSManaged public var creationDate: Date?
    @NSManaged public var modificationDate: Date?
}

extension CDTransactionEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTransactionEntity> {
        return NSFetchRequest<CDTransactionEntity>(entityName: "CDTransactionEntity")
    }
}

extension Array where Element == CDTransactionEntity {
    
    func toDomainModels() -> [Transaction] {
        map { $0.toDomainModel() }
    }
}

extension Array where Element == Transaction {
    
    func toCoreDataEntities(context: NSManagedObjectContext) -> [CDTransactionEntity] {
        map { CDTransactionEntity(context: context, from: $0) }
    }
} 