import Foundation

extension Decimal {
    init(stringOrNumber value: Any) throws {
        if let str = value as? String, let d = Decimal(string: str) {
            self = d; return
        }
        if let num = value as? NSNumber {
            self = num.decimalValue; return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Cannot convert value to Decimal"))
    }
} 