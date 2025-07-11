import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.transactionEditorViewModelFactory) private var editorVMFactory
    @Environment(\.analysisViewModelFactory) private var analysisVMFactory
    
    private enum EditorSheet: Identifiable {
        case edit(Transaction)
        
        var id: String {
            switch self {
            case .edit(let transaction):
                return "edit-\(transaction.id)"
            }
        }
    }
    
    @State private var activeSheet: EditorSheet?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        listContent
            .tint(.accent)
            .navigationTitle("Моя история")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward")
                            Text("Назад")
                        }
                    }
                    .tint(.secondaryAccent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.resetToDefaults()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .tint(.secondaryAccent)
                    .opacity(viewModel.isDefaultPeriod ? 0.3 : 1.0)
                    .disabled(viewModel.isDefaultPeriod)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isDefaultPeriod)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        let analysisViewModel = analysisVMFactory.makeAnalysisViewModel(
                            startDate: viewModel.startDate,
                            endDate: viewModel.endDate,
                            direction: viewModel.direction
                        )
                        AnalysisViewControllerRepresentable(viewModel: analysisViewModel)
                            .navigationTitle("Анализ")
                            .navigationBarTitleDisplayMode(.large)
                    } label: {
                        Image(systemName: "document")
                    }
                    .tint(.secondaryAccent)
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .edit(let transaction):
                    let editorViewModel = editorVMFactory.makeTransactionEditorViewModel(for: .edit(transaction))
                    TransactionEditorView(
                        viewModel: editorViewModel,
                        onComplete: {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    )
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
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var listContent: some View {
        List {
            if case .failed = viewModel.state, viewModel.transactions.isEmpty {
                Section {
                    errorView
                }
            } else {
                infoSection
                transactionsSection
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 16)
        }
    }
    
    private var infoSection: some View {
        Section("Период") {
            HStack {
                Text("Начало")
                Spacer()
                DatePicker(
                    "Начало",
                    selection: $viewModel.startDate,
                    in: ...Date.distantFuture,
                    displayedComponents: .date
                )
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .labelsHidden()
            }
            
            HStack {
                Text("Конец")
                Spacer()
                DatePicker(
                    "Конец",
                    selection: $viewModel.endDate,
                    in: ...Date.distantFuture,
                    displayedComponents: .date
                )
                .background(Color.accentColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .labelsHidden()
            }
            
            HStack {
                Text("Сумма")
                Spacer()
                Text(viewModel.total.rubleFormattedNoFraction)
            }
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
        .redacted(reason: viewModel.state == .loading ? .placeholder : [])
    }
    
    @ViewBuilder
    private var transactionsSection: some View {
        if !viewModel.transactions.isEmpty {
            Section {
                ForEach(viewModel.transactions) { transaction in
                    Button {
                        activeSheet = .edit(transaction)
                    } label: {
                        TransactionRowView(
                            transaction: transaction,
                            category: viewModel.categories[transaction.categoryId]
                        )
                        .tint(.primary)
                    }
                }
            } header: {
                HStack {
                    Text("Транзакции")
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
            .redacted(reason: viewModel.state == .loading ? .placeholder : [])
        } else if viewModel.isLoaded {
            ContentUnavailableView(
                "Нет операций",
                systemImage: viewModel.direction == .income ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis",
                description: Text("За выбранный период операций не найдено")
            )
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView(
            viewModel: HistoryViewModel(
                direction: .income,
                repository: TransactionsRepository(
                    transactionsService: MockTransactionsService(),
                    categoriesService: MockCategoriesService()
                )
            )
        )
    }
}
