import SwiftUI

struct MainTabView: View {
    @Environment(\.viewModelFactory) private var viewModelFactory
    
    var body: some View {
        TabView {
            transactionsList(for: .outcome)
                .tabItem {
                    Label("Расходы", systemImage: "chart.line.downtrend.xyaxis")
                }
            
            transactionsList(for: .income)
                .tabItem {
                    Label("Доходы", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            Text("Счет")
                .tabItem {
                    Label("Счет", systemImage: "creditcard")
                }
            
            Text("Статьи")
                .tabItem {
                    Label("Статьи", systemImage: "chart.pie")
                }
            
            Text("Настройки")
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
        }
    }
    
    private func transactionsList(for direction: Direction) -> some View {
        TransactionsListView(
            viewModel: viewModelFactory
                .makeTransactionsListViewModel(for: direction)
        )
    }
}

#Preview {
    MainTabView()
}
