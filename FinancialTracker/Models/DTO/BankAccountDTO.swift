import Foundation

struct BankAccountDTO: Decodable {
    let id: Int?
    let userId: Int?
    let name: String?
    let balance: String?
    let currency: String?
    let incomeStats: [StatItemDTO]?
    let expenseStats: [StatItemDTO]?
    let createdAt: Date?
    let updatedAt: Date?
}

struct StatItemDTO: Decodable {
    let categoryId: Int?
    let categoryName: String?
    let emoji: String?
    let amount: String?
} 