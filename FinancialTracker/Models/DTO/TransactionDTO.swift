import Foundation

struct TransactionDTO: Decodable {
    let id: Int?
    let account: TransactionAccountInfoDTO?
    let category: CategoryDTO?
    let accountId: Int?
    let categoryId: Int?
    let amount: String?
    let transactionDate: Date?
    let comment: String?
    let createdAt: Date?
    let updatedAt: Date?
}

struct TransactionAccountInfoDTO: Decodable {
    let id: Int?
    let name: String?
    let balance: String?
    let currency: String?
} 
