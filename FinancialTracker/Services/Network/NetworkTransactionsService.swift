import Foundation

struct NetworkTransactionsService: TransactionsServiceProtocol {
    private let client: NetworkClient
    private let cache: GenericFileCache<[Transaction]>
    
    init(client: NetworkClient) {
        self.client = client
        self.cache = GenericFileCache<[Transaction]>(
            fileName: "transactions.json", 
            decoder: JSONCoding.decoder, 
            encoder: JSONCoding.encoder
        )
    }

    func getTransactions(
        from startDate: Date,
        to endDate: Date,
        direction: Category.Direction
    ) async throws -> [Transaction] {
        let accountId = 1
        
        do {
            return try await fetchFromNetwork(accountId: accountId, startDate: startDate, endDate: endDate)
        } catch {
            if let cachedTransactions = try? await cache.load() {
                return cachedTransactions.filter {
                    $0.transactionDate >= startDate && $0.transactionDate <= endDate
                }
            }
            throw error
        }
    }
    
    private func fetchFromNetwork(accountId: Int, startDate: Date, endDate: Date) async throws -> [Transaction] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let query = [
            URLQueryItem(name: "startDate", value: formatter.string(from: startDate)),
            URLQueryItem(name: "endDate", value: formatter.string(from: endDate))
        ]
        
        var endpoint = Endpoint(path: "/transactions/account/\(accountId)/period", method: .get)
        endpoint.query = query

        let dtoList: [TransactionDTO] = try await client.request(endpoint, body: Optional<Int>.none)
        let transactions = dtoList.compactMap { TransactionDTOToDomainConverter.convert($0) }
        
        try? await cache.save(transactions)
        return transactions
    }

    func createTransaction(_ request: TransactionRequest) async throws -> Transaction {
        struct Body: Encodable {
            let accountId: Int
            let categoryId: Int
            let amount: String
            let transactionDate: String
            let comment: String?
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(accountId, forKey: .accountId)
                try container.encode(categoryId, forKey: .categoryId)
                try container.encode(amount, forKey: .amount)
                try container.encode(transactionDate, forKey: .transactionDate)
                try container.encode(comment, forKey: .comment)
            }
            
            enum CodingKeys: String, CodingKey {
                case accountId, categoryId, amount, transactionDate, comment
            }
        }
        
        let formatter = ISO8601DateFormatter()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        let amountString = numberFormatter.string(from: request.amount as NSDecimalNumber) ?? "0.00"
        
        let body = Body(
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: amountString,
            transactionDate: formatter.string(from: request.transactionDate),
            comment: request.comment
        )

        let endpoint = Endpoint(path: "/transactions", method: .post)
        let dto: TransactionDTO = try await client.request(endpoint, body: body, encoder: JSONCoding.encoder)
        guard let transaction = TransactionDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert TransactionDTO to Transaction"])
        }
        return transaction
    }

    func updateTransaction(id: Int, with request: TransactionRequest) async throws -> Transaction {
        struct Body: Encodable {
            let accountId: Int
            let categoryId: Int
            let amount: String
            let transactionDate: String
            let comment: String?
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(accountId, forKey: .accountId)
                try container.encode(categoryId, forKey: .categoryId)
                try container.encode(amount, forKey: .amount)
                try container.encode(transactionDate, forKey: .transactionDate)
                try container.encode(comment, forKey: .comment)
            }
            
            enum CodingKeys: String, CodingKey {
                case accountId, categoryId, amount, transactionDate, comment
            }
        }

        let formatter = ISO8601DateFormatter()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        let amountString = numberFormatter.string(from: request.amount as NSDecimalNumber) ?? "0.00"
        
        let body = Body(
            accountId: request.accountId,
            categoryId: request.categoryId,
            amount: amountString,
            transactionDate: formatter.string(from: request.transactionDate),
            comment: request.comment 
        )
        
        let endpoint = Endpoint(path: "/transactions/\(id)", method: .patch)
        let dto: TransactionDTO = try await client.request(endpoint, body: body, encoder: JSONCoding.encoder)
        guard let transaction = TransactionDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert TransactionDTO to Transaction"])
        }
        return transaction
    }
 
    func deleteTransaction(withId id: Int) async throws -> Transaction {
        let endpoint = Endpoint(path: "/transactions/\(id)", method: .delete)
        let dto: TransactionDTO = try await client.request(endpoint, body: Optional<Int>.none)
        guard let transaction = TransactionDTOToDomainConverter.convert(dto) else {
            throw NSError(domain: "ConversionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert TransactionDTO to Transaction"])
        }
        return transaction
    }
}
