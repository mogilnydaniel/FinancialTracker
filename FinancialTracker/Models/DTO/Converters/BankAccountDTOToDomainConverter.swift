import Foundation

struct BankAccountDTOToDomainConverter {
    static func convert(_ dto: BankAccountDTO) -> BankAccount? {
        guard let id = dto.id,
              let name = dto.name,
              let balanceString = dto.balance,
              let balance = Decimal(string: balanceString),
              let currencyCode = dto.currency,
              let createdAt = dto.createdAt,
              let updatedAt = dto.updatedAt else {
            return nil
        }
        
        let userId = dto.userId ?? 0
        let currency = BankAccount.Currency(code: currencyCode)
        
        return BankAccount(
            id: id,
            userId: userId,
            name: name,
            balance: balance,
            currency: currency,
            creationDate: createdAt,
            modificationDate: updatedAt
        )
    }
} 