import SwiftUI

struct TransactionsListView: View {
    @ObservedObject var viewModel: TransactionsListViewModel
    @Environment(\.di) private var di
    @Environment(\.transactionEditorViewModelFactory) private var editorVMFactory
    
    private enum EditorSheet: Identifiable {
        case create
        case edit(Transaction)
        
        var id: String {
            switch self {
            case .create:
                return "create"
            case .edit(let transaction):
                return "edit-\(transaction.id)"
            }
        }
    }
    
    @State private var activeSheet: EditorSheet?
    
    var body: some View {
        NavigationStack {
            listContent
                .navigationTitle(viewModel.direction == .income ? "Мои доходы" : "Мои расходы")
                .navigationBarTitleDisplayMode(.large)
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Spacer()
                        floatingActionButton
                    }
                    .animation(.bouncy, value: viewModel.isLoaded)
                }
                .toolbar {
                    historyToolbarItem
                }
                .task {
                    await viewModel.loadInitialData()
                }
                .alert("Ошибка", isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                ), actions: {
                    Button("ОК", role: .cancel) {}
                }, message: {
                    Text(viewModel.errorMessage ?? "Неизвестная ошибка")
                })
                .sheet(item: $activeSheet) { sheet in
                    let mode: TransactionEditorViewModel.Mode = switch sheet {
                    case .create: .create(viewModel.direction)
                    case .edit(let transaction): .edit(transaction)
                    }
                    
                    let editorViewModel = editorVMFactory.makeTransactionEditorViewModel(for: mode)
                    TransactionEditorView(
                        viewModel: editorViewModel,
                        onComplete: {
                            Task { @MainActor in
                                await viewModel.refresh()
                            }
                        }
                    )
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
        .refreshable {
            await viewModel.refresh()
            try? await Task.sleep(nanoseconds: 300_000_000)        }
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
                    Button {
                        activeSheet = .edit(transaction)
                    } label: {
                        HStack {
                            TransactionRowView(
                                transaction: transaction,
                                category: viewModel.categories[transaction.categoryId]
                            )
                            .redacted(reason: viewModel.state == .loading ? .placeholder : [])
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(.tertiaryLabel))
                        }
                        .tint(.primary)
                    }
                }
            } else if viewModel.isLoaded {
                ContentUnavailableView(
                    "Нет операций",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Пока нет \(viewModel.direction == .income ? "доходов" : "расходов").")
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
    
    private var historyToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                HistoryView(
                    viewModel: di.historyVMFactory.makeHistoryViewModel(for: viewModel.direction)
                )
            } label: {
                Image(systemName: "clock")
            }
            .tint(Color("SecondaryAccentColor"))
        }
    }
    
    @ViewBuilder
    private var floatingActionButton: some View {
        if viewModel.isLoaded {
            Button {
                activeSheet = .create
            } label: {
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
            direction: Category.Direction.income,
            repository: TransactionsRepository(
                transactionsService: MockTransactionsService(),
                categoriesService: MockCategoriesService()
            )
        )
    )
}
