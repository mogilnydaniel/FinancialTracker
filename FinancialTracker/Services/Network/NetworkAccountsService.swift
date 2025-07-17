import Foundation

struct NetworkAccountsService: BankAccountsServiceProtocol {
    private let client: NetworkClient
    private let accountId: Int = 1
    private let cache: GenericFileCache<BankAccount>

    init(client: NetworkClient) {
        self.client = client
        self.cache = GenericFileCache<BankAccount>(
            fileName: "account.json", 
            decoder: JSONCoding.decoder, 
            encoder: JSONCoding.encoder
        )
    }

    func getBankAccount() async throws -> BankAccount {
        let endpoint = Endpoint(path: "/accounts/\(accountId)", method: .get)
        do {
            let dto: BankAccountDTO = try await client.request(endpoint, body: Optional<String>.none)
            guard let result = BankAccountDTOToDomainConverter.convert(dto) else {
                throw NSError(domain: "ConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert BankAccountDTO to BankAccount"])
            }
            try? await cache.save(result)
            return result
        } catch {
            if let cached = try? await cache.load() { return cached }
            throw error
        }
    }

    func updateBankAccount(_ updatedAccount: BankAccount) async throws -> BankAccount {
        struct UpdateAccountBody: Encodable {
            let name: String
            let balance: Decimal
            let currency: String
        }
        let body = UpdateAccountBody(name: updatedAccount.name, balance: updatedAccount.balance, currency: updatedAccount.currency.code)
        let endpoint = Endpoint(path: "/accounts/\(updatedAccount.id)", method: .put)
        let dto: BankAccountDTO = try await client.request(endpoint, body: body, encoder: JSONCoding.encoder)
        guard let updated = BankAccountDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert BankAccountDTO to BankAccount"])
        }
        try? await cache.save(updated)
        return updated
    }
} 
