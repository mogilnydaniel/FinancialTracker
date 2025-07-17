import Foundation

actor HybridCategoriesService: CategoriesServiceProtocol {
    private let persistence: CategoriesPersistenceProtocol
    private let networkClient: NetworkClient
    
    init(
        persistence: CategoriesPersistenceProtocol,
        networkClient: NetworkClient
    ) {
        self.persistence = persistence
        self.networkClient = networkClient
    }
    
    func getCategories() async throws -> [Category] {
        let localCategories = try await persistence.getCategories()
        
        if !localCategories.isEmpty {
            Task {
                await syncFromNetwork()
            }
            return localCategories
        }
        
        return try await fetchAndSaveFromNetwork()
    }
    
    func getCategories(direction: Category.Direction) async throws -> [Category] {
        let localCategories = try await persistence.getCategories(direction: direction)
        
        if !localCategories.isEmpty {
            Task {
                await syncFromNetworkByDirection(direction)
            }
            return localCategories
        }
        
        return try await fetchAndSaveFromNetworkByDirection(direction)
    }
    
    private func fetchAndSaveFromNetwork() async throws -> [Category] {
        let endpoint = Endpoint(path: "/categories", method: .get)
        let dto: [CategoryDTO] = try await networkClient.request(endpoint, body: Optional<Int>.none)
        let categories = dto.compactMap(CategoryDTOToDomainConverter.convert)
        
        try await persistence.syncCategories(categories)
        return categories
    }
    
    private func fetchAndSaveFromNetworkByDirection(_ direction: Category.Direction) async throws -> [Category] {
        let isIncome = direction == .income
        let endpoint = Endpoint(path: "/categories/type/\(isIncome)", method: .get)
        let dto: [CategoryDTO] = try await networkClient.request(endpoint, body: Optional<Int>.none)
        let categories = dto.compactMap(CategoryDTOToDomainConverter.convert)
        
        for category in categories {
            let existingCategories = try await persistence.getCategories()
            if !existingCategories.contains(where: { $0.id == category.id }) {
                try await persistence.saveCategories([category])
            }
        }
        
        return categories
    }
    
    private func syncFromNetwork() async {
        do {
            _ = try await fetchAndSaveFromNetwork()
        } catch {
        }
    }
    
    private func syncFromNetworkByDirection(_ direction: Category.Direction) async {
        do {
            _ = try await fetchAndSaveFromNetworkByDirection(direction)
        } catch {
        }
    }
} 
