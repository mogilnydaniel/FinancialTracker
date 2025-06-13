import Foundation

protocol CategoriesServiceProtocol {
    func getCategories() async throws -> [Category]
    func getCategories(direction: Category.Direction) async throws -> [Category]
}

actor MockCategoriesService: CategoriesServiceProtocol {
    private let categories = [
        Category(id: 1, name: "Зарплата", icon: "💰", direction: .income),
        Category(id: 2, name: "Подарки", icon: "🎁", direction: .income),
        Category(id: 3, name: "Продукты", icon: "🛒", direction: .outcome),
        Category(id: 4, name: "Транспорт", icon: "🚗", direction: .outcome),
        Category(id: 5, name: "Развлечения", icon: "🎉", direction: .outcome),
        Category(id: 6, name: "Коммунальные услуги", icon: "🏠", direction: .outcome)
    ]

    func getCategories() async throws -> [Category] {
        try await Task.sleep(for: .seconds(0.5))
        return categories
    }

    func getCategories(direction: Category.Direction) async throws -> [Category] {
        try await Task.sleep(for: .seconds(0.5))
        return categories.filter { $0.direction == direction }
    }
}
