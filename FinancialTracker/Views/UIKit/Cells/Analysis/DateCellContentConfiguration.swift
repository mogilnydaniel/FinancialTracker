import UIKit

struct DateCellContentConfiguration: UIContentConfiguration, Hashable {
    var title: String?
    var date: Date?
    var onDateChanged: ((Date) -> Void)?

    func makeContentView() -> UIView & UIContentView {
        return DateCellContentView(configuration: self)
    }
    
    func updated(for state: UIConfigurationState) -> Self {
        return self
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(date)
    }

    static func == (lhs: DateCellContentConfiguration, rhs: DateCellContentConfiguration) -> Bool {
        lhs.title == rhs.title && lhs.date == rhs.date
    }
} 