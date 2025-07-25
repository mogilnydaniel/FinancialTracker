import UIKit
import PieChart

struct PieChartCellContentConfiguration: UIContentConfiguration, Hashable {
    var entities: [Entity]
    
    func makeContentView() -> UIView & UIContentView {
        return PieChartCellContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        return self
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(entities)
    }
    
    static func == (lhs: PieChartCellContentConfiguration, rhs: PieChartCellContentConfiguration) -> Bool {
        lhs.entities == rhs.entities
    }
} 