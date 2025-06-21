import SwiftUI

struct TransactionsListView: View {
    @State var viewModel: TransactionsListViewModel
    
    @Environment(\.historyViewModelFactory) private var historyViewModelFactory
    
    var body: some View {
        NavigationStack {
            listContent
                .navigationTitle(viewModel.direction == .income ? "Доходы сегодня" : "Расходы сегодня")
                .navigationBarTitleDisplayMode(.large)
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Spacer()
                        floatingActionButton
                    }
                    .animation(.bouncy, value: viewModel.isLoaded)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            HistoryView(
                                viewModel: historyViewModelFactory.makeHistoryViewModel(for: viewModel.direction)
                            )
                        } label: {
                            Image(systemName: "clock")
                        }
                        .tint(Color("SecondaryAccentColor"))
                    }
                }
                .task {
                    await viewModel.loadInitialData()
                }
        }
    }
    
    private var listContent: some View {
        List {
            totalSection
            transactionsSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 16)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    private var totalSection: some View {
        Section {
            HStack {
                Text("Всего")
                Spacer()
                Text(viewModel.total.rubleFormatted)
            }
            .redacted(reason: viewModel.state == .loading ? .placeholder : [])
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var transactionsSection: some View {
        Section {
            if case .failed = viewModel.state, viewModel.transactions.isEmpty {
                errorView
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } else if !viewModel.transactions.isEmpty {
                ForEach(viewModel.transactions) { transaction in
                    TransactionRowView(
                        transaction: transaction,
                        category: viewModel.categories[transaction.categoryId]
                    )
                    .redacted(reason: viewModel.state == .loading ? .placeholder : [])
                }
            } else if viewModel.isLoaded {
                ContentUnavailableView(
                    "Нет операций",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("За сегодня пока нет \(viewModel.direction == .income ? "доходов" : "расходов").")
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        } header: {
            HStack {
                Text("ОПЕРАЦИИ")
                Spacer()
                Picker("Сортировка", selection: $viewModel.sort) {
                    ForEach(TransactionSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .textCase(nil)
            }
        }
    }
    
    private var errorView: some View {
        ContentUnavailableView {
            Label("Ошибка загрузки", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(viewModel.errorMessage ?? "Неизвестная ошибка")
        } actions: {
            Button("Повторить") {
                viewModel.refreshTrigger()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(minHeight: 200)
    }
    
    @ViewBuilder
    private var floatingActionButton: some View {
        if viewModel.isLoaded {
            Button(action: { }) {
                Image(systemName: "plus")
                    .font(.title.weight(.semibold))
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(radius: 4, x: 0, y: 4)
            }
            .padding()
        }
    }
}

#Preview {
    TransactionsListView(
        viewModel: TransactionsListViewModel(
            direction: .income,
            repository: TransactionsRepository(
                transactionsService: MockTransactionsService(),
                categoriesService: MockCategoriesService()
            )
        )
    )
}
