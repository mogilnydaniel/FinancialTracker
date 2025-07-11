import Foundation

struct AnalysisOperationItem: Hashable {
    let category: Category
    let totalAmount: Decimal
    let percentage: Double
    let comment: String?
} 