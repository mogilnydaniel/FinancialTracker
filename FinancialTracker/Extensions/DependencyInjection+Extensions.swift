import SwiftUI

private struct ViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any TransactionsListViewModelFactoryProtocol = TransactionsListViewModelFactory(dependencyInjector: DependencyInjector.shared)
}

private struct HistoryViewModelFactoryKey: EnvironmentKey {
    static let defaultValue: any HistoryViewModelFactoryProtocol = HistoryViewModelFactory(dependencyInjector: DependencyInjector.shared)
}

extension EnvironmentValues {
    var viewModelFactory: any TransactionsListViewModelFactoryProtocol {
        get { self[ViewModelFactoryKey.self] }
        set { self[ViewModelFactoryKey.self] = newValue }
    }
    
    var historyViewModelFactory: any HistoryViewModelFactoryProtocol {
        get { self[HistoryViewModelFactoryKey.self] }
        set { self[HistoryViewModelFactoryKey.self] = newValue }
    }
} 
