import UIKit

struct SortCellContentConfiguration: UIContentConfiguration, Hashable {
    var selected: AnalysisScreenItem.SortType
    var onSelectionChanged: ((AnalysisScreenItem.SortType) -> Void)?

    func makeContentView() -> UIView & UIContentView {
        return SortCellContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
        return self
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(selected)
    }

    static func == (lhs: SortCellContentConfiguration, rhs: SortCellContentConfiguration) -> Bool {
        lhs.selected == rhs.selected
    }
} 