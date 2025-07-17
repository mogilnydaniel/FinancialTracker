import Foundation

protocol CategoriesPersistenceProtocol: Sendable {
    func getCategories() async throws -> [Category]
    func getCategories(direction: Category.Direction) async throws -> [Category]
    func getCategory(id: Int) async throws -> Category?
    func saveCategories(_ categories: [Category]) async throws
    func deleteAllCategories() async throws
    func syncCategories(_ categories: [Category]) async throws
} 