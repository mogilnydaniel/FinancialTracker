import Foundation

extension Transaction {
    static func parse(jsonObject: Any) -> Transaction? {
        guard let dict = jsonObject as? [String: Any],
              let id = dict["id"] as? Int,
              let accountId = dict["accountId"] as? Int,
              let categoryId = dict["categoryId"] as? Int,
              let amountString = dict["amount"] as? String,
              let amount = Decimal(string: amountString),
              let transactionDateString = dict["transactionDate"] as? String,
              let createdAtString = dict["createdAt"] as? String,
              let updatedAtString = dict["updatedAt"] as? String
        else { return nil }
        
        guard let transactionDate = try? Date(transactionDateString, strategy: .iso8601),
              let creationDate = try? Date(createdAtString, strategy: .iso8601),
              let modificationDate = try? Date(updatedAtString, strategy: .iso8601)
        else { return nil }
        
        let comment = dict["comment"] as? String
        
        return Transaction(
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
    
    var jsonObject: Any {
        var result: [String: Any] = [
            "id": id,
            "accountId": accountId,
            "categoryId": categoryId,
            "amount": String(describing: amount),
            "transactionDate": transactionDate.formatted(.iso8601),
            "createdAt": creationDate.formatted(.iso8601),
            "updatedAt": modificationDate.formatted(.iso8601)
        ]
        
        comment.map { result["comment"] = $0 }

        return result
    }
}
