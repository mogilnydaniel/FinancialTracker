import Foundation
import CoreData

final class CoreDataBankAccountsPersistence: BankAccountsPersistenceProtocol {
    
    private let container: NSPersistentContainer
    
    init(container: NSPersistentContainer) {
        self.container = container
    }
    
    func getBankAccount() async throws -> BankAccount? {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBankAccountEntity> = CDBankAccountEntity.fetchRequest()
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return entities.first?.toDomainModel()
        }
    }
    
    func getAllBankAccounts() async throws -> [BankAccount] {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBankAccountEntity> = CDBankAccountEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDBankAccountEntity.creationDate, ascending: false)]
            
            let entities = try context.fetch(request)
            return entities.toDomainModels()
        }
    }
    
    func getBankAccount(by id: Int) async throws -> BankAccount? {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBankAccountEntity> = CDBankAccountEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %d", id)
            request.fetchLimit = 1
            
            let entities = try context.fetch(request)
            return entities.first?.toDomainModel()
        }
    }
    
    @discardableResult
    func createBankAccount(_ bankAccount: BankAccount) async throws -> BankAccount {
        try await container.performInBackground { context in
            if try self.bankAccountExistsInContext(id: bankAccount.id, context: context) {
                throw PersistenceError.conversionFailed("BankAccount with id \(bankAccount.id) already exists")
            }
            
            let entity = CDBankAccountEntity(context: context, from: bankAccount)
            try context.save()
            
            return entity.toDomainModel()
        }
    }
    
    @discardableResult
    func updateBankAccount(_ bankAccount: BankAccount) async throws -> BankAccount {
        try await container.performInBackground { context in
            guard let existingEntity = try self.getBankAccountEntityInContext(by: bankAccount.id, context: context) else {
                throw PersistenceError.notFound
            }
            
            existingEntity.update(from: bankAccount)
            try context.save()
            
            return existingEntity.toDomainModel()
        }
    }
    
    @discardableResult
    func deleteBankAccount(by id: Int) async throws -> BankAccount? {
        try await container.performInBackground { context in
            guard let entity = try self.getBankAccountEntityInContext(by: id, context: context) else {
                return nil
            }
            
            let bankAccount = entity.toDomainModel()
            context.delete(entity)
            try context.save()
            
            return bankAccount
        }
    }
    
    func saveBankAccount(_ account: BankAccount) async throws -> BankAccount {
        try await updateBankAccount(account)
    }
    
    func deleteBankAccount() async throws {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBankAccountEntity> = CDBankAccountEntity.fetchRequest()
            let entities = try context.fetch(request)
            
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    func accountExists() async throws -> Bool {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBankAccountEntity> = CDBankAccountEntity.fetchRequest()
            let count = try context.count(for: request)
            return count > 0
        }
    }
    
    func clearAllBankAccounts() async throws {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBankAccountEntity> = CDBankAccountEntity.fetchRequest()
            let entities = try context.fetch(request)
            
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
        }
    }
    
    func bankAccountsCount() async throws -> Int {
        try await container.performInBackground { context in
            let request: NSFetchRequest<CDBankAccountEntity> = CDBankAccountEntity.fetchRequest()
            return try context.count(for: request)
        }
    }
    
    func bankAccountExists(id: Int) async throws -> Bool {
        try await container.performInBackground { context in
            try self.bankAccountExistsInContext(id: id, context: context)
        }
    }
    
    private func getBankAccountEntityInContext(by id: Int, context: NSManagedObjectContext) throws -> CDBankAccountEntity? {
        let request: NSFetchRequest<CDBankAccountEntity> = CDBankAccountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        request.fetchLimit = 1
        
        let entities = try context.fetch(request)
        return entities.first
    }
    
    private func bankAccountExistsInContext(id: Int, context: NSManagedObjectContext) throws -> Bool {
        let request: NSFetchRequest<CDBankAccountEntity> = CDBankAccountEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", id)
        
        let count = try context.count(for: request)
        return count > 0
    }
} 