import Foundation

struct NetworkCategoriesService: CategoriesServiceProtocol {
    private let client: NetworkClient
    private let cache = GenericFileCache<[Category]>(fileName: "categories.json")

    init(client: NetworkClient) {
        self.client = client
    }

    func getCategories() async throws -> [Category] {
        let endpoint = Endpoint(path: "/categories", method: .get)
        do {
            let dto: [CategoryDTO] = try await client.request(endpoint, body: Optional<Int>.none)
            let result = dto.compactMap(CategoryDTOToDomainConverter.convert)
            
            try? await cache.save(result)
            return result
        } catch {
            if let cached = try? await cache.load() { return cached }
            throw error
        }
    }

    func getCategories(direction: Category.Direction) async throws -> [Category] {
        let isIncome = direction == .income
        let endpoint = Endpoint(path: "/categories/type/\(isIncome)", method: .get)
        do {
            let dto: [CategoryDTO] = try await client.request(endpoint, body: Optional<Int>.none)
            let categories = dto.compactMap(CategoryDTOToDomainConverter.convert)
            try? await cache.save(categories)
            return categories
        } catch {
            if let cached = try? await cache.load() { return cached.filter { $0.direction == direction } }
            throw error
        }
    }
} 