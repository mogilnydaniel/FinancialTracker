import Foundation
import SwiftData

@ModelActor
actor SwiftDataTransactionsPersistence: TransactionsPersistenceProtocol {
    
    func getAllTransactions() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionEntity>(
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.toDomainModels()
    }
    
    func getTransaction(by id: Int) async throws -> Transaction? {
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.id == id
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        return entities.first?.toDomainModel()
    }
    
    func getTransactions(from startDate: Date, to endDate: Date) async throws -> [Transaction] {
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.transactionDate >= startDate && entity.transactionDate <= endDate
        }
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.transactionDate, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.toDomainModels()
    }
    
    @discardableResult
    func createTransaction(_ transaction: Transaction) async throws -> Transaction {
        if try await transactionExists(id: transaction.id) {
            throw PersistenceError.conversionFailed("Transaction with id \(transaction.id) already exists")
        }
        
        let entity = TransactionEntity(from: transaction)
        modelContext.insert(entity)
        try modelContext.save()
        
        return entity.toDomainModel()
    }
    
    @discardableResult
    func updateTransaction(_ transaction: Transaction) async throws -> Transaction {
        guard let existingEntity = try await getTransactionEntity(by: transaction.id) else {
            throw PersistenceError.notFound
        }
        
        existingEntity.update(from: transaction)
        try modelContext.save()
        
        return existingEntity.toDomainModel()
    }
    
    @discardableResult
    func deleteTransaction(by id: Int) async throws -> Transaction? {
        guard let entity = try await getTransactionEntity(by: id) else {
            return nil
        }
        
        let transaction = entity.toDomainModel()
        modelContext.delete(entity)
        try modelContext.save()
        
        return transaction
    }
    
    
    func saveTransactions(_ transactions: [Transaction]) async throws {
        let entities = transactions.map { TransactionEntity(from: $0) }
        for entity in entities {
            modelContext.insert(entity)
        }
        try modelContext.save()
    }
    
    func deleteTransactions(by ids: [Int]) async throws {
        let predicate = #Predicate<TransactionEntity> { entity in
            ids.contains(entity.id)
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }
    
    func clearAllTransactions() async throws {
        let descriptor = FetchDescriptor<TransactionEntity>()
        let entities = try modelContext.fetch(descriptor)
        
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    
    func transactionsCount() async throws -> Int {
        let descriptor = FetchDescriptor<TransactionEntity>()
        return try modelContext.fetchCount(descriptor)
    }
    
    func transactionExists(id: Int) async throws -> Bool {
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.id == id
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        let count = try modelContext.fetchCount(descriptor)
        return count > 0
    }
    
    func getLatestTransaction() async throws -> Transaction? {
        var descriptor = FetchDescriptor<TransactionEntity>(
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let entities = try modelContext.fetch(descriptor)
        return entities.first?.toDomainModel()
    }
    
    
    func syncTransactions(_ transactions: [Transaction]) async throws {
        guard !transactions.isEmpty else { return }

        let ids = transactions.map { $0.id }
        let predicate = #Predicate<TransactionEntity> { entity in
            ids.contains(entity.id)
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        let existing = try modelContext.fetch(descriptor)
        var existingMap: [Int: TransactionEntity] = [:]
        for entity in existing { existingMap[entity.id] = entity }
        for transaction in transactions {
            if let entity = existingMap[transaction.id] {
                entity.update(from: transaction)
            } else {
                let entity = TransactionEntity(from: transaction)
                modelContext.insert(entity)
            }
        }
        try modelContext.save()
    }
    
    private func getTransactionEntity(by id: Int) async throws -> TransactionEntity? {
        let predicate = #Predicate<TransactionEntity> { entity in
            entity.id == id
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        return entities.first
    }
} 
