import Foundation

struct Transaction: Identifiable, Codable, Equatable {
    let id: Int
    let accountId: Int
    let categoryId: Int
    let amount: Decimal
    let transactionDate: Date
    let comment: String?
    let creationDate: Date
    let modificationDate: Date
}

extension Transaction {
    static let placeholder = Transaction(
        id: 0,
        accountId: 0,
        categoryId: 0,
        amount: 0,
        transactionDate: Date(),
        comment: "Placeholder comment",
        creationDate: Date(),
        modificationDate: Date()
    )
}
