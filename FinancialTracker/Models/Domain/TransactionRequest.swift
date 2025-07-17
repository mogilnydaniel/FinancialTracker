import Foundation

struct TransactionRequest: Codable {
    let accountId: Int
    let categoryId: Int
    let amount: Decimal
    let transactionDate: Date
    let comment: String?
} 