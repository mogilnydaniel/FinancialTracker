import SwiftUI

struct TransactionEditorView: View {
    @StateObject var viewModel: TransactionEditorViewModel
    
    var onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    pickerField
                    amountField
                    dateField
                    timeField
                }
                
                Section {
                    commentField
                }
                
                if viewModel.canDelete {
                    Section {
                        Button(role: .destructive) {
                            viewModel.isShowingDeleteConfirmation = true
                        } label: {
                            Text(viewModel.deleteButtonTitle)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        Task {
                            await viewModel.save {
                                onComplete()
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.loadInitialData()
            }
            .alert(item: $viewModel.alertItem) { item in
                Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
            }
            .alert(
                "Подтверждение",
                isPresented: $viewModel.isShowingDeleteConfirmation,
                actions: {
                    Button("Удалить", role: .destructive) {
                        Task {
                            await viewModel.delete {
                                onComplete()
                                dismiss()
                            }
                        }
                    }
                    Button("Отмена", role: .cancel) {}
                },
                message: {
                    Text("Вы уверены, что хотите удалить эту операцию? Действие нельзя будет отменить.")
                }
            )
        }
    }
    
    private var pickerField: some View {
        Picker("Статья", selection: $viewModel.selectedCategoryId) {
            Text("Не выбрана").tag(nil as Int?)
            ForEach(viewModel.availableCategories) { category in
                Text(category.name).tag(category.id as Int?)
            }
        }
        .pickerStyle(.menu)
    }
    
    private var amountField: some View {
        HStack {
            Text("Сумма")
            TextField("0", text: $viewModel.amount)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("₽")
                .foregroundStyle(.secondary)
        }
    }
    
    private var dateField: some View {
        HStack {
            Text("Дата")
            Spacer()
            Text(viewModel.transactionDate, style: .date)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    DatePicker(
                        "Дата",
                        selection: $viewModel.transactionDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .blendMode(.destinationOver)
                }
        }
    }
    
    private var timeField: some View {
        HStack {
            Text("Время")
            Spacer()
            Text(viewModel.transactionDate, style: .time)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    DatePicker(
                        "Время",
                        selection: $viewModel.transactionDate,
                        displayedComponents: .hourAndMinute
                    )
                    .blendMode(.destinationOver)
                }
        }
    }
    
    private var commentField: some View {
        TextField("Комментарий", text: $viewModel.comment, axis: .vertical)
            .lineLimit(3...)
    }
}

extension TransactionEditorViewModel {
    var navigationTitle: String {
        switch mode {
        case .create(let direction):
            return direction == .income ? "Новый доход" : "Новый расход"
        case .edit:
            return "Редактирование"
        }
    }
}

#Preview {
    let di = DIContainer.production
    let viewModel = TransactionEditorViewModel(
        mode: .create(.outcome),
        repository: di.transactionsRepository,
        categoriesService: di.categoriesService,
        bankAccountsService: di.bankAccountsService
    )
    
    TransactionEditorView(
        viewModel: viewModel,
        onComplete: {
            print("Completed")
        }
    )
} 