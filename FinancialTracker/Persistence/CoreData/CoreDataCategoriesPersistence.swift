import Foundation
import CoreData

final class CoreDataCategoriesPersistence: CategoriesPersistenceProtocol {
    
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    func getCategories() async throws -> [Category] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDCategoryEntity> = CDCategoryEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCategoryEntity.name, ascending: true)]
            
            let entities = try context.fetch(request)
            return entities.toDomainModels()
        }
    }
    
    func getCategory(id: Int) async throws -> Category? {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDCategoryEntity> = CDCategoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", id)
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return entities.first?.toDomainModel()
        }
    }
    
    func getCategories(direction: Category.Direction) async throws -> [Category] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDCategoryEntity> = CDCategoryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "directionRawValue == %@", direction.rawValue)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDCategoryEntity.name, ascending: true)]
            
            let entities = try context.fetch(request)
            return entities.toDomainModels()
        }
    }
    
    @discardableResult
    func createCategory(_ category: Category) async throws -> Category {
        try await container.performInBackground { context in
            if try self.categoryExistsInContext(id: category.id, context: context) {
                throw PersistenceError.conversionFailed("Category with id \(category.id) already exists")
            }
            
            let entity = CDCategoryEntity(context: context, from: category)
            try context.save()
            
            return entity.toDomainModel()
        }
    }
    
    @discardableResult
    func updateCategory(_ category: Category) async throws -> Category {
        try await container.performInBackground { context in
            guard let existingEntity = try self.getCategoryEntityInContext(by: category.id, context: context) else {
                throw PersistenceError.notFound
            }
            
            existingEntity.update(from: category)
            try context.save()
            
            return existingEntity.toDomainModel()
        }
    }
    
    @discardableResult
    func deleteCategory(by id: Int) async throws -> Category? {
        try await container.performInBackground { context in
            guard let entity = try self.getCategoryEntityInContext(by: id, context: context) else {
                return nil
            }
            
            let category = entity.toDomainModel()
            context.delete(entity)
            try context.save()
            
            return category
        }
    }
    
    func saveCategories(_ categories: [Category]) async throws {
        try await container.performInBackground { context in
            for category in categories {
                if !(try self.categoryExistsInContext(id: category.id, context: context)) {
                    _ = CDCategoryEntity(context: context, from: category)
                }
            }
            try context.save()
        }
    }
    
    func syncCategories(_ categories: [Category]) async throws {
        try await saveCategories(categories)
    }
    
    func deleteAllCategories() async throws {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDCategoryEntity> = CDCategoryEntity.fetchRequest()
            let entities = try context.fetch(request)
            
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    func categoriesCount() async throws -> Int {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDCategoryEntity> = CDCategoryEntity.fetchRequest()
            return try context.count(for: request)
        }
    }
    
    func categoryExists(id: Int) async throws -> Bool {
        try await container.performInBackground { context in
            try self.categoryExistsInContext(id: id, context: context)
        }
    }
    
    private func getCategoryEntityInContext(by id: Int, context: NSManagedObjectContext) throws -> CDCategoryEntity? {
        let request: NSFetchRequest<CDCategoryEntity> = CDCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        
        let entities = try context.fetch(request)
        return entities.first
    }
    
    private func categoryExistsInContext(id: Int, context: NSManagedObjectContext) throws -> Bool {
        let request: NSFetchRequest<CDCategoryEntity> = CDCategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        let count = try context.count(for: request)
        return count > 0
    }
} 