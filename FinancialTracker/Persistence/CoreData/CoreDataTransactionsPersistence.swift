import Foundation
import CoreData

final class CoreDataTransactionsPersistence: TransactionsPersistenceProtocol {
    
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    func getAllTransactions() async throws -> [Transaction] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDTransactionEntity> = CDTransactionEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTransactionEntity.creationDate, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.toDomainModels()
        }
    }
    
    func getTransaction(by id: Int) async throws -> Transaction? {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDTransactionEntity> = CDTransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", id)
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return entities.first?.toDomainModel()
        }
    }
    
    func getTransactions(from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDTransactionEntity> = CDTransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "transactionDate >= %@ AND transactionDate <= %@", startDate as NSDate, endDate as NSDate)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTransactionEntity.transactionDate, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.toDomainModels()
        }
    }
    
    @discardableResult
    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        try await container.performInBackground { context in
            if try self.transactionExistsInContext(id: transaction.id, context: context) {
                throw PersistenceError.conversionFailed("Transaction with id \(transaction.id) already exists")
            }
            
            let entity = CDTransactionEntity(context: context, from: transaction)
            try context.save()
            
            return entity.toDomainModel()
        }
    }
    
    @discardableResult
    func updateTransaction(_ transaction: Transaction) async throws -> Transaction {
        try await container.performInBackground { context in
            guard let existingEntity = try self.getTransactionEntityInContext(by: transaction.id, context: context) else {
                throw PersistenceError.notFound
            }
            
            existingEntity.update(from: transaction)
            try context.save()
            
            return existingEntity.toDomainModel()
        }
    }
    
    @discardableResult
    func deleteTransaction(by id: Int) async throws -> Transaction? {
        try await container.performInBackground { context in
            guard let entity = try self.getTransactionEntityInContext(by: id, context: context) else {
                return nil
            }
            
            let transaction = entity.toDomainModel()
            context.delete(entity)
            try context.save()
            
            return transaction
        }
    }
    
    func saveTransactions(_ transactions: [Transaction]) async throws {
        try await container.performInBackground { context in
            for transaction in transactions {
                _ = CDTransactionEntity(context: context, from: transaction)
            }
            try context.save()
        }
    }
    
    func deleteTransactions(by ids: [Int]) async throws {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDTransactionEntity> = CDTransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)
            
            let entities = try context.fetch(request)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    func clearAllTransactions() async throws {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDTransactionEntity> = CDTransactionEntity.fetchRequest()
            let entities = try context.fetch(request)
            
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    func transactionsCount() async throws -> Int {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDTransactionEntity> = CDTransactionEntity.fetchRequest()
            return try context.count(for: request)
        }
    }
    
    func transactionExists(id: Int) async throws -> Bool {
        try await container.performInBackground { context in
            try self.transactionExistsInContext(id: id, context: context)
        }
    }
    
    func getLatestTransaction() async throws -> Transaction? {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDTransactionEntity> = CDTransactionEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDTransactionEntity.creationDate, ascending: false)]
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return entities.first?.toDomainModel()
        }
    }
    
    func syncTransactions(_ transactions: [Transaction]) async throws {
        try await container.performInBackground { context in
            for transaction in transactions {
                if try self.transactionExistsInContext(id: transaction.id, context: context) {
                    if let existingEntity = try self.getTransactionEntityInContext(by: transaction.id, context: context) {
                        existingEntity.update(from: transaction)
                    }
                } else {
                    _ = CDTransactionEntity(context: context, from: transaction)
                }
            }
            try context.save()
        }
    }
    
    private func getTransactionEntityInContext(by id: Int, context: NSManagedObjectContext) throws -> CDTransactionEntity? {
        let request: NSFetchRequest<CDTransactionEntity> = CDTransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        
        let entities = try context.fetch(request)
        return entities.first
    }
    
    private func transactionExistsInContext(id: Int, context: NSManagedObjectContext) throws -> Bool {
        let request: NSFetchRequest<CDTransactionEntity> = CDTransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        let count = try context.count(for: request)
        return count > 0
    }
} 