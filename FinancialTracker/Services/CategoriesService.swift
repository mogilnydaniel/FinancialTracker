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
        Category(id: 6, name: "Коммунальные услуги", icon: "🏠", direction: .outcome),
        Category(id: 7, name: "Одежда", icon: "👔", direction: .outcome),
        Category(id: 8, name: "Медицина", icon: "💊", direction: .outcome),
        Category(id: 9, name: "Спортзал", icon: "🏋️‍♂️", direction: .outcome),
        Category(id: 10, name: "Инвестиции", icon: "📈", direction: .income),
        Category(id: 11, name: "Фриланс", icon: "💻", direction: .income),
        Category(id: 12, name: "Аренда квартиры", icon: "🏢", direction: .outcome),
        Category(id: 13, name: "Домашние животные", icon: "🐕", direction: .outcome),
        Category(id: 14, name: "Образование", icon: "📚", direction: .outcome),
        Category(id: 15, name: "Рестораны", icon: "🍽️", direction: .outcome)
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
