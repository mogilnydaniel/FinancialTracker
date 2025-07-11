import Foundation

@MainActor
protocol AnalysisViewModelFactoryProtocol {
    func makeAnalysisViewModel(
        startDate: Date,
        endDate: Date,
        direction: Category.Direction
    ) -> AnalysisViewModel
}

struct AnalysisViewModelFactory: AnalysisViewModelFactoryProtocol {
    unowned let di: DIContainer

    func makeAnalysisViewModel(
        startDate: Date,
        endDate: Date,
        direction: Category.Direction
    ) -> AnalysisViewModel {
        let viewModel = AnalysisViewModel(repository: di.transactionsRepository, direction: direction)
        viewModel.startDate = startDate
        viewModel.endDate = endDate
        return viewModel
    }
} 