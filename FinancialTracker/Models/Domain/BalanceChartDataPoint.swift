import Foundation

struct BalanceChartDataPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let amount: Decimal
    
    var type: BalanceChangeType {
        amount >= 0 ? .income : .expense
    }
    
    enum BalanceChangeType: String {
        case income = "Доход"
        case expense = "Расход"
    }
}

enum ChartTimePeriod: String, CaseIterable, Identifiable {
    case days = "По дням"
    case months = "По месяцам"
    
    var id: String { self.rawValue }
    
    var daysCount: Int {
        switch self {
        case .days: return 30
        case .months: return 24 * 30
        }
    }
} 
