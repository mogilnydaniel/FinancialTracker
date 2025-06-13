import Foundation

struct BankAccount: Identifiable {
    enum Currency: Equatable {
        case rub
        case usd
        case eur
        case other(String)
        
        var code: String {
            switch self {
            case .rub: return "RUB"
            case .usd: return "USD"
            case .eur: return "EUR"
            case .other(let code): return code
            }
        }
        
        init(code: String) {
            switch code.uppercased() {
            case "RUB": self = .rub
            case "USD": self = .usd
            case "EUR": self = .eur
            default: self = .other(code)
            }
        }
    }
    
    let id: Int
    let userId: Int
    let name: String
    let balance: Decimal
    let currency: Currency
    let creationDate: Date
    let modificationDate: Date
}
