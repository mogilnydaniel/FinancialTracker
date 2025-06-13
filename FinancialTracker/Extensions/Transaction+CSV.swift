import Foundation

extension Transaction {
    static func fromCSVString(_ csvString: String) -> [Transaction] {
        let lines = csvString.components(separatedBy: .newlines)
        var transactions: [Transaction] = []
        
        for line in lines.dropFirst() {
            if let transaction = parseCSVLine(line) {
                transactions.append(transaction)
            }
        }
        
        return transactions
    }
    
    private static func parseCSVLine(_ line: String) -> Transaction? {
        let fields = parseCSVFields(line)
        guard fields.count >= 8,
              let id = Int(fields[0]),
              let accountId = Int(fields[1]),
              let categoryId = Int(fields[2])
        else { return nil }
        
        guard let transactionDate = try? Date(fields[5], strategy: .iso8601),
              let createdAt = try? Date(fields[6], strategy: .iso8601),
              let updatedAt = try? Date(fields[7], strategy: .iso8601)
        else { return nil }
        
        guard let amount = Decimal(string: fields[4])
        else { return nil }

        
        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: transactionDate,
            comment: fields[3].isEmpty ? nil : fields[3],
            creationDate: createdAt,
            modificationDate: updatedAt
        )
    }
    
    private static func parseCSVFields(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        fields.append(currentField)
        return fields
    }
    
    var csvString: String {
        let commentField = comment ?? ""
        
        return [
            escapeCSVField(id.description),
            escapeCSVField(accountId.description),
            escapeCSVField(categoryId.description),
            escapeCSVField(commentField),
            escapeCSVField(String(describing: amount)),
            escapeCSVField(transactionDate.formatted(.iso8601)),
            escapeCSVField(creationDate.formatted(.iso8601)),
            escapeCSVField(modificationDate.formatted(.iso8601))
        ].joined(separator: ",")
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
    
    static var csvHeader: String {
        return "id,accountId,categoryId,comment,amount,transactionDate,createdAt,updatedAt"
    }
}

extension Array where Element == Transaction {
    var csvString: String {
        let header = Transaction.csvHeader
        let rows = self.map { $0.csvString }
        return ([header] + rows).joined(separator: "\n")
    }
}
