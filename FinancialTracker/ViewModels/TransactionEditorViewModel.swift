import Foundation
import SwiftUI
import Combine

@MainActor
final class TransactionEditorViewModel: ObservableObject {
    enum Mode: Equatable {
        case create(Category.Direction)
        case edit(Transaction)
        
        var direction: Category.Direction {
            switch self {
            case .create(let direction):
                return direction
            case .edit(let transaction):
                return transaction.amount >= 0 ? .income : .outcome
            }
        }
        
        static func == (lhs: Mode, rhs: Mode) -> Bool {
            switch (lhs, rhs) {
            case (.create(let lDir), .create(let rDir)):
                return lDir == rDir
            case (.edit(let lTrans), .edit(let rTrans)):
                return lTrans.id == rTrans.id
            default:
                return false
            }
        }
    }
    
    struct AlertItem: Identifiable {
        let id = UUID()
        var title: String
        var message: String
    }
    
    let mode: Mode
    private let repository: any TransactionsRepositoryProtocol
    private let categoriesService: any CategoriesServiceProtocol
    private let bankAccountsService: any BankAccountsServiceProtocol
    
    @Published var amount: String = ""
    @Published var selectedCategoryId: Int?
    @Published var transactionDate: Date = .now
    @Published var comment: String = ""
    
    @Published private(set) var availableCategories: [Category] = []
    @Published private(set) var isLoading: Bool = false
    @Published var alertItem: AlertItem?
    @Published var isShowingDeleteConfirmation = false
    
    var canDelete: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }
    
    var deleteButtonTitle: String {
        switch mode {
        case .edit(let transaction):
            return transaction.amount < 0 ? "Удалить расход" : "Удалить доход"
        case .create:
            return ""
        }
    }

    private enum AmountConst {
        static let decimalSeparator: String = Locale.current.decimalSeparator ?? "."
        static let allowedCharacters: CharacterSet = {
            var set = CharacterSet.decimalDigits
            set.insert(charactersIn: decimalSeparator)
            return set
        }()
    }

    func processAmountInput(_ text: String) {
        var filtered = text.unicodeScalars.filter { AmountConst.allowedCharacters.contains($0) }
            .map { String($0) }
            .joined()

        if let firstIndex = filtered.firstIndex(of: Character(AmountConst.decimalSeparator)) {
            let before = String(filtered[..<firstIndex])
            let afterStart = filtered.index(after: firstIndex)
            let after = filtered[afterStart...]
                .replacingOccurrences(of: AmountConst.decimalSeparator, with: "")
            filtered = before + AmountConst.decimalSeparator + after
        }
        amount = filtered
    }

    init(
        mode: Mode,
        repository: any TransactionsRepositoryProtocol,
        categoriesService: any CategoriesServiceProtocol,
        bankAccountsService: any BankAccountsServiceProtocol
    ) {
        self.mode = mode
        self.repository = repository
        self.categoriesService = categoriesService
        self.bankAccountsService = bankAccountsService
    }
    
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            availableCategories = try await categoriesService.getCategories(direction: mode.direction)
            
            if case .edit(let transaction) = mode {
                let amountValue = abs(transaction.amount)
                amount = String(describing: amountValue)
                
                selectedCategoryId = transaction.categoryId
                transactionDate = transaction.transactionDate
                comment = transaction.comment ?? ""
            }
            
        } catch {
            alertItem = AlertItem(
                title: "Ошибка загрузки",
                message: ErrorMapper.message(for: error)
            )
        }
    }
    
    func save(onSuccess: @escaping () -> Void) async {
        guard let categoryId = selectedCategoryId else {
            alertItem = AlertItem(
                title: "Категория не выбрана",
                message: "Пожалуйста, выберите категорию для операции."
            )
            return
        }
        
        let sanitizedAmount = amount
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: AmountConst.decimalSeparator, with: ".")
        
        guard let amountValue = Decimal(string: sanitizedAmount), amountValue > 0 else {
            alertItem = AlertItem(
                title: "Некорректная сумма",
                message: "Пожалуйста, введите корректную сумму больше нуля."
            )
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let account = try await bankAccountsService.getBankAccount()
            
            let finalAmount = amountValue
            
            let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let request = TransactionRequest(
                accountId: account.id,
                categoryId: categoryId,
                amount: finalAmount,
                transactionDate: transactionDate,
                comment: trimmedComment.isEmpty ? nil : trimmedComment
            )
            
            switch mode {
            case .create:
                try await repository.createTransaction(request)
            case .edit(let transaction):
                try await repository.updateTransaction(id: transaction.id, with: request)
            }
            
            onSuccess()
            
        } catch {
            alertItem = AlertItem(
                title: "Ошибка сохранения",
                message: ErrorMapper.message(for: error)
            )
        }
    }
    
    func delete(onSuccess: @escaping () -> Void) async {
        guard case .edit(let transaction) = mode else {
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await repository.deleteTransaction(withId: transaction.id)
            onSuccess()
        } catch {
            alertItem = AlertItem(
                title: "Ошибка удаления",
                message: ErrorMapper.message(for: error)
            )
        }
    }
} 
