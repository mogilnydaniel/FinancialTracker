import Foundation

struct TransactionDTOToDomainConverter {
    static func convert(_ dto: TransactionDTO) -> Transaction? {
        guard let id = dto.id,
              let amountString = dto.amount,
              let amount = Decimal(string: amountString),
              let transactionDate = dto.transactionDate,
              let createdAt = dto.createdAt else {
            return nil
        }
        
        let accountId: Int
        let categoryId: Int
        
        if let account = dto.account, let accId = account.id {
            accountId = accId
        } else if let accId = dto.accountId {
            accountId = accId
        } else {
            return nil
        }
        
        if let category = dto.category, let catId = category.id {
            categoryId = catId
        } else if let catId = dto.categoryId {
            categoryId = catId
        } else {
            return nil
        }
        
        let modificationDate = dto.updatedAt ?? createdAt
        
        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: dto.comment ?? "",
            creationDate: createdAt,
            modificationDate: modificationDate
        )
    }
} 
