import Foundation

struct Transaction: Identifiable, Equatable {
    let id: Int
    let accountId: Int
    let categoryId: Int
    let amount: Decimal
    let transactionDate: Date
    let comment: String?
    let creationDate: Date
    let modificationDate: Date
}
