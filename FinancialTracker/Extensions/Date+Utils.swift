import Foundation

extension Date {
    static var today: Date {
        Date()
    }
    
    static var oneMonthAgo: Date {
        Calendar.current.date(byAdding: .month, value: -1, to: today) ?? today
    }
    
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        let startOfNextDay = Calendar.current.date(byAdding: .day, value: 1, to: self.startOfDay) ?? self
        return Calendar.current.date(byAdding: .second, value: -1, to: startOfNextDay) ?? self
    }
}

extension Decimal {
    var rubleFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        
        if let formattedNumber = formatter.string(from: NSDecimalNumber(decimal: self)) {
            return "\(formattedNumber) ₽"
        }
        return "\(self) ₽"
    }
    
    var rubleFormattedNoFraction: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        
        if let formattedNumber = formatter.string(from: NSDecimalNumber(decimal: self)) {
            return "\(formattedNumber) ₽"
        }
        return "\(self) ₽"
    }
} 
