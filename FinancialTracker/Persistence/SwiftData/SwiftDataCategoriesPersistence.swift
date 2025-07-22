import Foundation
import SwiftData

@ModelActor
actor SwiftDataCategoriesPersistence: CategoriesPersistenceProtocol {
    
    func getCategories() async throws -> [Category] {
        let descriptor = FetchDescriptor<CategoryEntity>(
            sortBy: [SortDescriptor(\.id)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.compactMap { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(error.localizedDescription)
        }
    }
    
    func getCategories(direction: Category.Direction) async throws -> [Category] {
        let directionString = direction.rawValue
        let predicate = #Predicate<CategoryEntity> { entity in
            entity.direction == directionString
        }
        
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.id)]
        )
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.compactMap { $0.toDomain() }
        } catch {
            throw PersistenceError.fetchFailed(error.localizedDescription)
        }
    }
    
    func getCategory(id: Int) async throws -> Category? {
        let predicate = #Predicate<CategoryEntity> { entity in
            entity.id == id
        }
        
        let descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(error.localizedDescription)
        }
    }
    
    func saveCategories(_ categories: [Category]) async throws {
        do {
            for category in categories {
                let entity = CategoryEntity.fromDomain(category)
                modelContext.insert(entity)
            }
            
            try modelContext.save()
        } catch {
            throw PersistenceError.saveFailed(error.localizedDescription)
        }
    }
    
    func deleteAllCategories() async throws {
        do {
            let descriptor = FetchDescriptor<CategoryEntity>()
            let entities = try modelContext.fetch(descriptor)
            
            for entity in entities {
                modelContext.delete(entity)
            }
            
            try modelContext.save()
        } catch {
            throw PersistenceError.deleteFailed(error.localizedDescription)
        }
    }
    
    func syncCategories(_ categories: [Category]) async throws {
        do {
            try await deleteAllCategories()
            try await saveCategories(categories)
        } catch {
            throw PersistenceError.syncFailed(error.localizedDescription)
        }
    }
} 