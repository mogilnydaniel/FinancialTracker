import Foundation

protocol ArticlesServiceProtocol {
    func getArticles() async throws -> [Category]
}

struct MockArticlesService: ArticlesServiceProtocol {
    private let categoriesService: any CategoriesServiceProtocol
    
    init(categoriesService: any CategoriesServiceProtocol) {
        self.categoriesService = categoriesService
    }
    
    func getArticles() async throws -> [Category] {
        try await categoriesService.getCategories()
    }
} 