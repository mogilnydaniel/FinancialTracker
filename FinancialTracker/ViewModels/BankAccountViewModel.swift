import Foundation
import SwiftUI

@Observable
final class BankAccountViewModel {
    enum Mode {
        case view
        case edit
    }
    
    private let service: any BankAccountsServiceProtocol
    private let transactionsService: any TransactionsServiceProtocol
    
    var account: BankAccount?
    var state: LoadingState = .idle
    var mode: Mode = .view
    var balanceText: String = ""
    var selectedCurrency: BankAccount.Currency = .rub
    var isBalanceHidden: Bool = false
    
    var selectedPeriod: ChartTimePeriod = .days {
        didSet {
            guard oldValue != selectedPeriod else { return }
            clearChartSelection()
            Task {
                await updateChartData()
            }
        }
    }
    
    var chartData: [BalanceChartDataPoint] = []
    var chartDateLabels: (start: Date, mid: Date, end: Date)? = nil
    var selectedDataPoint: BalanceChartDataPoint? = nil
    
    private enum Const {
        static let maxFractionDigits = 2
        static let locale = Locale(identifier: "ru_RU")
        static let groupingSeparator = " "
        static let decimalSeparatorComma = ","
        static let decimalSeparatorDot = "."
    }
    
    init(service: any BankAccountsServiceProtocol, transactionsService: any TransactionsServiceProtocol) {
        self.service = service
        self.transactionsService = transactionsService

        NotificationCenter.default.addObserver(self, selector: #selector(handleTransactionChange(_:)), name: .transactionDidChange, object: nil)
    }

    @objc private func handleTransactionChange(_ n: Notification) {
        Task { [weak self] in
            await self?.refresh()
            await self?.updateChartData()
        }
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
            await updateChartData()
        } catch {
            await MainActor.run { state = .failed(ErrorMapper.wrap(error)) }
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
            await updateChartData()
        } catch {
            await MainActor.run { state = .failed(ErrorMapper.wrap(error)) }
        }
    }
    
    func clearChartSelection() {
        selectedDataPoint = nil
    }
    
    @MainActor
    private func updateChartData() async {
        guard let account = account else { 

            return 
        }
        

        
        switch selectedPeriod {
        case .days:
            await calculateDailyBalanceData(accountId: account.id)
        case .months:
            await calculateMonthlyBalanceData(accountId: account.id)
        }
        
        print("DEBUG: Chart data updated, count: \(chartData.count)")
    }
    
    private func calculateDailyBalanceData(accountId: Int) async {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) else { return }
        
        do {
            async let incomeTransactions = transactionsService.getTransactions(
                from: startDate,
                to: endDate,
                direction: .income
            )
            
            async let expenseTransactions = transactionsService.getTransactions(
                from: startDate,
                to: endDate,
                direction: .outcome
            )
            
            let (incomes, expenses) = try await (incomeTransactions, expenseTransactions)
            let allTransactions = incomes + expenses
            
            let accountTransactions = allTransactions.filter { $0.accountId == accountId }
            
            let groupedByDay = Dictionary(grouping: accountTransactions) { 
                calendar.startOfDay(for: $0.transactionDate) 
            }
            
            let dailyChanges: [BalanceChartDataPoint] = (0..<30).compactMap { dayOffset in
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { return nil }
                let dayStart = calendar.startOfDay(for: date)
                let transactionsForDay = groupedByDay[dayStart] ?? []
                
                let dailyTotal = transactionsForDay.reduce(Decimal.zero) { partialResult, transaction in
                    return partialResult + transaction.amount
                }
                
                return BalanceChartDataPoint(date: dayStart, amount: dailyTotal)
            }
            
            await MainActor.run {
                self.chartData = dailyChanges.reversed()
                
                if let firstDate = self.chartData.first?.date,
                   let midDate = calendar.date(byAdding: .day, value: 14, to: firstDate) {
                    self.chartDateLabels = (start: firstDate, mid: midDate, end: endDate)
                }
            }
            
        } catch {
            await MainActor.run {
                self.chartData = []
                self.chartDateLabels = nil
            }
        }
    }
    
    private func calculateMonthlyBalanceData(accountId: Int) async {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .month, value: -23, to: endDate) else { return }
        
        do {
            async let incomeTransactions = transactionsService.getTransactions(
                from: startDate,
                to: endDate,
                direction: .income
            )
            
            async let expenseTransactions = transactionsService.getTransactions(
                from: startDate,
                to: endDate,
                direction: .outcome
            )
            
            let (incomes, expenses) = try await (incomeTransactions, expenseTransactions)
            let allTransactions = incomes + expenses
            
            let accountTransactions = allTransactions.filter { $0.accountId == accountId }
            
            let groupedByMonth = Dictionary(grouping: accountTransactions) { transaction -> Date in
                let components = calendar.dateComponents([.year, .month], from: transaction.transactionDate)
                return calendar.date(from: components) ?? calendar.startOfDay(for: transaction.transactionDate)
            }
            
            let monthlyChanges: [BalanceChartDataPoint] = (0..<24).compactMap { monthOffset in
                guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: endDate) else { return nil }
                let components = calendar.dateComponents([.year, .month], from: monthDate)
                guard let startOfMonth = calendar.date(from: components) else { return nil }
                
                let transactionsForMonth = groupedByMonth[startOfMonth] ?? []
                
                let monthlyTotal = transactionsForMonth.reduce(Decimal.zero) { partialResult, transaction in
                    return partialResult + transaction.amount
                }
                
                return BalanceChartDataPoint(date: startOfMonth, amount: monthlyTotal)
            }
            
            await MainActor.run {
                self.chartData = monthlyChanges.reversed()
                
                if let firstDate = self.chartData.first?.date,
                   let midDate = calendar.date(byAdding: .month, value: 12, to: firstDate) {
                    self.chartDateLabels = (start: firstDate, mid: midDate, end: endDate)
                }
            }
            
        } catch {
            await MainActor.run {
                self.chartData = []
                self.chartDateLabels = nil
            }
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
                await updateChartData()
            } catch {
                await MainActor.run {
                    state = .failed(ErrorMapper.wrap(error))
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
