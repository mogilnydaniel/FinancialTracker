import Foundation
import SwiftData

@Model
final class TransactionEntity {
    
    @Attribute(.unique) var id: Int
    var accountId: Int
    var categoryId: Int
    
    private var amountString: String
    
    var transactionDate: Date
    var comment: String?
    var creationDate: Date
    var modificationDate: Date

    var amount: Decimal {
        get {
            return Decimal(string: amountString) ?? 0
        }
        set {
            amountString = newValue.description
        }
    }

    
    init(
        id: Int,
        accountId: Int,
        categoryId: Int,
        amount: Decimal,
        transactionDate: Date,
        comment: String? = nil,
        creationDate: Date,
        modificationDate: Date
    ) {
        self.id = id
        self.accountId = accountId
        self.categoryId = categoryId
        self.amountString = amount.description
        self.transactionDate = transactionDate
        self.comment = comment
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
    
    convenience init(from transaction: Transaction) {
        self.init(
            id: transaction.id,
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment,
            creationDate: transaction.creationDate,
            modificationDate: transaction.modificationDate
        )
    }
    
    func toDomainModel() -> Transaction {
        Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            creationDate: creationDate,
            modificationDate: modificationDate
        )
    }
    
    func update(from transaction: Transaction) {
        self.accountId = transaction.accountId
        self.categoryId = transaction.categoryId
        self.amount = transaction.amount
        self.transactionDate = transaction.transactionDate
        self.comment = transaction.comment
        self.modificationDate = transaction.modificationDate
    }
}


extension Array where Element == TransactionEntity {
    
    func toDomainModels() -> [Transaction] {
        map { $0.toDomainModel() }
    }
}

extension Array where Element == Transaction {

    func toEntities() -> [TransactionEntity] {
        map { TransactionEntity(from: $0) }
    }
} 
