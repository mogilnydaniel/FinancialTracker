import SwiftUI

struct MainTabView: View {
    @Environment(\.di) private var di
    
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
            
            NavigationStack {
                BankAccountView()
            }
                .tabItem {
                    Label("Счет", systemImage: "creditcard")
                }
            
            ArticlesView()
                .tabItem {
                    Label("Статьи", systemImage: "list.bullet.rectangle")
                }
            
            Text("Настройки")
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
        }
        .background(ShakeDetector())
    }
    
    private func transactionsList(for direction: Direction) -> some View {
        TransactionsListView(
            viewModel: di.transactionsListVMFactory
                .makeTransactionsListViewModel(for: direction)
        )
    }
}

#Preview {
    MainTabView()
}
