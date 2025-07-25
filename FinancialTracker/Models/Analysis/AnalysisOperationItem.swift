import Foundation
import PieChart

struct AnalysisOperationItem: Hashable {
    let category: Category
    let totalAmount: Decimal
    let percentage: Double
    let comment: String?
}

extension AnalysisOperationItem {
    var pieChartEntity: Entity {
        Entity(value: totalAmount, label: category.name)
    }
}

extension Array where Element == AnalysisOperationItem {
    var pieChartEntities: [Entity] {
        map { $0.pieChartEntity }
    }
} 