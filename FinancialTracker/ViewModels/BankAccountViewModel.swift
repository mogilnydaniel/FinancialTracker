import Foundation
import SwiftUI

@Observable
final class BankAccountViewModel {
    enum Mode {
        case view
        case edit
    }
    
    private let service: any BankAccountsServiceProtocol
    
    var account: BankAccount?
    var state: LoadingState = .idle
    var mode: Mode = .view
    var balanceText: String = ""
    var selectedCurrency: BankAccount.Currency = .rub
    var isBalanceHidden: Bool = false
    
    private enum Const {
        static let maxFractionDigits = 2
        static let locale = Locale(identifier: "ru_RU")
        static let groupingSeparator = " "
        static let decimalSeparatorComma = ","
        static let decimalSeparatorDot = "."
    }
    
    init(service: any BankAccountsServiceProtocol) {
        self.service = service
    }
    
    func load() async {
        guard state == .idle else { return }
        await MainActor.run { state = .loading }
        do {
            let acc = try await service.getBankAccount()
            await MainActor.run {
                account = acc
                balanceText = Self.displayFormatter.string(for: acc.balance) ?? ""
                selectedCurrency = acc.currency
                state = .loaded
            }
        } catch {
            await MainActor.run { state = .failed(error) }
        }
    }
    
    func refresh() async {
        do {
            let acc = try await service.getBankAccount()
            await MainActor.run {
                account = acc
                balanceText = Self.displayFormatter.string(for: acc.balance) ?? ""
                selectedCurrency = acc.currency
                state = .loaded
            }
        } catch {
            await MainActor.run { state = .failed(error) }
        }
    }
    
    func startEditing() {
        mode = .edit
        if let acc = account {
            balanceText = Self.displayFormatter.string(for: acc.balance) ?? ""
            selectedCurrency = acc.currency
        }
    }
    
    func saveChanges() {
        guard var acc = account else { return }
        let sanitized = balanceText
            .replacingOccurrences(of: Const.groupingSeparator, with: "")
            .replacingOccurrences(of: Const.decimalSeparatorComma, with: Const.decimalSeparatorDot)
        let newBalance = Decimal(string: sanitized) ?? acc.balance
        acc = BankAccount(
            id: acc.id,
            userId: acc.userId,
            name: acc.name,
            balance: newBalance,
            currency: selectedCurrency,
            creationDate: acc.creationDate,
            modificationDate: Date()
        )
        Task {
            do {
                let updated = try await service.updateBankAccount(acc)
                await MainActor.run {
                    account = updated
                    mode = .view
                    balanceText = Self.displayFormatter.string(for: updated.balance) ?? ""
                }
            } catch {
                await MainActor.run {
                    state = .failed(error)
                }
            }
        }
    }
    
    func cancelEditing() {
        mode = .view
    }
    
    func selectCurrency(_ currency: BankAccount.Currency) {
        selectedCurrency = currency
    }
    
    func toggleHidden() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isBalanceHidden.toggle()
        }
    }
    
    func processInputChange(_ text: String) {
        let allowed = "0123456789" + Const.decimalSeparatorDot + Const.decimalSeparatorComma
        let filtered = text.filter { allowed.contains($0) }
        let sanitized = filtered
            .replacingOccurrences(of: Const.groupingSeparator, with: "")
            .replacingOccurrences(of: Const.decimalSeparatorComma, with: Const.decimalSeparatorDot)

        guard let dec = Decimal(string: sanitized) else {
            balanceText = filtered
            return
        }

        if let formatted = Self.inputFormatter.string(for: dec) {
            balanceText = formatted
        } else {
            balanceText = filtered
        }
    }
    
    func pasteBalance(_ str: String) {
        processInputChange(str)
    }
    
    func formatCurrentInput() {
        let sanitized = balanceText.replacingOccurrences(of: Const.groupingSeparator, with: "")
            .replacingOccurrences(of: Const.decimalSeparatorComma, with: Const.decimalSeparatorDot)
        if let dec = Decimal(string: sanitized) {
            balanceText = Self.inputFormatter.string(for: dec) ?? balanceText
        }
    }
    
    private static let displayFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = Const.groupingSeparator
        f.decimalSeparator = Const.decimalSeparatorComma
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = Const.maxFractionDigits
        f.locale = Const.locale
        return f
    }()
    
    private static let inputFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = Const.groupingSeparator
        f.decimalSeparator = Const.decimalSeparatorDot
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = Const.maxFractionDigits
        f.locale = Const.locale
        return f
    }()
} 