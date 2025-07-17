import Foundation
import SwiftData

@ModelActor
actor SwiftDataBankAccountsPersistence: BankAccountsPersistenceProtocol {
    
    func getBankAccount() async throws -> BankAccount? {
        let descriptor = FetchDescriptor<BankAccountEntity>()
        
        do {
            let entities = try modelContext.fetch(descriptor)
            return entities.first?.toDomain()
        } catch {
            throw PersistenceError.fetchFailed(error.localizedDescription)
        }
    }
    
    func saveBankAccount(_ account: BankAccount) async throws -> BankAccount {
        do {
            let existingDescriptor = FetchDescriptor<BankAccountEntity>()
            let existing = try modelContext.fetch(existingDescriptor)
            
            for entity in existing {
                modelContext.delete(entity)
            }
            
            let entity = BankAccountEntity.fromDomain(account)
            modelContext.insert(entity)
            
            try modelContext.save()
            
            let savedAccount = entity.toDomain()
            return savedAccount
        } catch {
            throw PersistenceError.saveFailed(error.localizedDescription)
        }
    }
    
    func deleteBankAccount() async throws {
        do {
            let descriptor = FetchDescriptor<BankAccountEntity>()
            let entities = try modelContext.fetch(descriptor)
            
            for entity in entities {
                modelContext.delete(entity)
            }
            
            try modelContext.save()
        } catch {
            throw PersistenceError.deleteFailed(error.localizedDescription)
        }
    }
    
    func accountExists() async throws -> Bool {
        do {
            let descriptor = FetchDescriptor<BankAccountEntity>()
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            throw PersistenceError.fetchFailed(error.localizedDescription)
        }
    }
} 