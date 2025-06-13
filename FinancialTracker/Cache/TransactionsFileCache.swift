import Foundation

actor TransactionsFileCache {
    private(set) var transactions: [Int: Transaction] = [:]
    private let fileName: String
    
    init(fileName: String = "transactions.json") {
        self.fileName = fileName
    }

    func add(_ transaction: Transaction) {
        transactions[transaction.id] = transaction
    }
    
    @discardableResult
    func remove(by id: Int) -> Transaction? {
        return transactions.removeValue(forKey: id)
    }
    
    func save() throws {
        let fileURL = try getFileURL()
        let jsonArray = transactions.values.map { $0.jsonObject }
        let data = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
        try data.write(to: fileURL)
    }
    
    func load() throws {
        let fileURL = try getFileURL()
        
        guard FileManager.default.fileExists(atPath: fileURL.path)
        else {
            transactions = [:]
            return
        }
        
        let data = try Data(contentsOf: fileURL)
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            transactions = [:]
            return
        }
        
        let loadedTransactions = jsonArray.compactMap { Transaction.parse(jsonObject: $0) }
        transactions = loadedTransactions.reduce(into: [:]) { $0[$1.id] = $1 }
    }
    
    private func getFileURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return directory.appendingPathComponent(fileName)
    }
}

