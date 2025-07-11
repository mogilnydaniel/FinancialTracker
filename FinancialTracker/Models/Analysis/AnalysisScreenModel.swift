import Foundation

enum AnalysisScreenSection: Hashable {
    case info
    case sort
    case total
    case operations
}

enum AnalysisScreenItem: Hashable {
    enum DateType: Hashable {
        case start
        case end
    }

    enum SortType: String, CaseIterable, Hashable {
        case date = "Дата"
        case amount = "Сумма"
    }

    case date(type: DateType, date: Date)
    case sum(Decimal)
    case sort(SortType)
    case operation(AnalysisOperationItem)
} 