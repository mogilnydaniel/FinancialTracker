import UIKit

struct AnalysisOperationCellContentConfiguration: UIContentConfiguration, Hashable {
    var item: AnalysisOperationItem?
    
    func makeContentView() -> UIView & UIContentView {
        return AnalysisOperationCellContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        return self
    }
} 