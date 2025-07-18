import Foundation

protocol CategoriesServiceProtocol {
    func getCategories() async throws -> [Category]
    func getCategories(direction: Category.Direction) async throws -> [Category]
}


