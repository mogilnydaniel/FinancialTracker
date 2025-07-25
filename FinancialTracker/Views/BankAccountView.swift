import SwiftUI
import Charts

struct BankAccountView: View {
    @State private var viewModel: BankAccountViewModel?
    @FocusState private var balanceFocused: Bool
    @State private var showCurrencyDialog = false
    
    @State private var dragLocation: CGPoint? = nil
    @State private var showDetailPopup: Bool = false
    @State private var longPressActivated: Bool = false
    private let chartHorizontalPadding: CGFloat = 10
    
    @Environment(\.di) private var di
    
    private enum Const {
        static let spoilerBlur: CGFloat = 6
        static let animationDuration = 0.25
    }
    
    private let xAxisDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"
        return formatter
    }()
    
    private let xAxisMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.yyyy"
        return formatter
    }()
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
                switch viewModel.state {
                case .idle, .loading:
                    content(viewModel: viewModel)
                        .redacted(reason: .placeholder)
                        .task { await viewModel.load() }
                case .failed(let error):
                    VStack {
                        Text(error.localizedDescription)
                        Button("Retry") { Task { await viewModel.load() } }
                    }
                case .loaded:
                    content(viewModel: viewModel)
                }
            } else {
                ProgressView()
                    .task {
                        viewModel = di.bankAccountVMFactory.makeBankAccountViewModel()
                    }
            }
        }
        .navigationTitle("Мой счет")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let viewModel = viewModel {
                    Button(viewModel.mode == .view ? "Редактировать" : "Сохранить") {
                        withAnimation(.easeInOut) {
                            if viewModel.mode == .view {
                                viewModel.startEditing()
                                balanceFocused = true
                            } else {
                                viewModel.saveChanges()
                            }
                        }
                    }
                    .tint(Color("SecondaryAccentColor"))
                    .disabled(viewModel.state == .loading)
                }
            }
        }
        .refreshable { 
            if let viewModel = viewModel {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await viewModel.refresh() 
            }
        }
        .tint(Color("SecondaryAccentColor"))
        .confirmationDialog("Валюта", isPresented: $showCurrencyDialog, titleVisibility: .visible) {
            if let viewModel = viewModel {
                ForEach([BankAccount.Currency.rub, .usd, .eur], id: \.code) { currency in
                    Button(label(for: currency)) {
                        if currency != viewModel.selectedCurrency {
                            viewModel.selectCurrency(currency)
                        }
                    }
                }
            }
            Button("Отмена", role: .cancel) {}
        }
        .tint(Color("SecondaryAccentColor"))
        .background(Color(.systemGroupedBackground).opacity(0.1))
        .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            viewModel?.toggleHidden()
        }
        .onTapGesture {
            if viewModel?.mode == .edit {
                balanceFocused = false
            }
        }
        .alert("Баланс на дату", isPresented: $showDetailPopup) {
            Button("OK") {
                longPressActivated = false
                showDetailPopup = false
            }
        } message: {
            if let selectedPoint = viewModel?.selectedDataPoint {
                Text("\(selectedPoint.date, style: .date)\n\(selectedPoint.amount.rubleFormatted)")
            }
        }
    }
    
    @ViewBuilder
    private func content(viewModel: BankAccountViewModel) -> some View {
        List {
            let balanceBG = viewModel.mode == .view ? Color("AccentColor") : Color(.systemBackground)
            let currencyBG = viewModel.mode == .view ? Color("AccentColor").opacity(0.25) : Color(.systemBackground)

            Section { 
                balanceRow(viewModel: viewModel) 
            }
                .listRowBackground(balanceBG)
                .animation(.easeInOut(duration: 0.3), value: viewModel.mode)

            Section { 
                currencyRow(viewModel: viewModel) 
            }
                .listRowBackground(currencyBG)
                .animation(.easeInOut(duration: 0.3), value: viewModel.mode)
            
            if viewModel.mode == .view && !viewModel.chartData.isEmpty {
                Section {
                    VStack(spacing: 20) {
                        HStack {
                            Text("История баланса")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        
                        Picker("Период", selection: Binding(
                            get: { viewModel.selectedPeriod },
                            set: { newValue in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.selectedPeriod = newValue
                                }
                            }
                        )) {
                            ForEach(ChartTimePeriod.allCases) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        balanceChart(viewModel: viewModel)
                    }
                    .padding(.vertical, 12)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: viewModel.mode)
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .listSectionSpacing(15)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 16)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .scrollTargetBehavior(.viewAligned)
    }
    
    @ViewBuilder
    private func balanceChart(viewModel: BankAccountViewModel) -> some View {
        let labels = viewModel.chartDateLabels
        
        Chart(viewModel.chartData) { dataPoint in
            RuleMark(
                x: .value("Дата", dataPoint.date),
                yStart: .value("Начало", 0),
                yEnd: .value("Конец", dataPoint.amount < 0 ? -Double(truncating: dataPoint.amount as NSDecimalNumber) : Double(truncating: dataPoint.amount as NSDecimalNumber))
            )
            .foregroundStyle(by: .value("Тип", dataPoint.type.rawValue))
            .lineStyle(StrokeStyle(lineWidth: viewModel.selectedPeriod == .days ? 8 : 4, lineCap: .round))
        }
        .chartForegroundStyleScale([
            BalanceChartDataPoint.BalanceChangeType.income.rawValue: Color.green,
            BalanceChartDataPoint.BalanceChangeType.expense.rawValue: Color.orange
        ])
        .chartXAxis {
            if let labels = labels {
                AxisMarks(preset: .aligned, values: [labels.start, labels.mid, labels.end]) { value in
                    if let date = value.as(Date.self) {
                        let formatter = viewModel.selectedPeriod == .days ? xAxisDateFormatter : xAxisMonthFormatter
                        AxisValueLabel {
                            Text(date, formatter: formatter)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: true))
        .chartLegend(.hidden)
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color.clear)
        }
        .frame(height: 180)
        .padding(.horizontal, chartHorizontalPadding)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .chartOverlay { chartProxy in
            BalanceChartInteractionOverlay(
                proxy: chartProxy,
                chartData: Binding(
                    get: { viewModel.chartData },
                    set: { _ in }
                ),
                selectedDataPoint: Binding(
                    get: { viewModel.selectedDataPoint },
                    set: { viewModel.selectedDataPoint = $0 }
                ),
                dragLocation: $dragLocation,
                showDetailPopup: $showDetailPopup,
                longPressActivated: $longPressActivated,
                chartHorizontalPadding: chartHorizontalPadding,
                clearChartSelection: viewModel.clearChartSelection
            )
        }
    }
    
    private func balanceRow(viewModel: BankAccountViewModel) -> some View {
        Button {
            if viewModel.mode == .edit {
                balanceFocused = true
            }
        } label: {
            HStack {
                Text("💰 Баланс")
                Spacer()
                ZStack {
                    if viewModel.mode == .edit {
                        HStack(spacing: 4) {
                            TextField("0", text: Binding(
                                get: { viewModel.balanceText },
                                set: { viewModel.processInputChange($0) }
                            ))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($balanceFocused)
                                .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
                                    if balanceFocused, let string = UIPasteboard.general.string {
                                        viewModel.pasteBalance(string)
                                    }
                                }
                            Text(viewModel.selectedCurrency.symbol)
                                .opacity(0)
                        }
                        .transition(.opacity)
                    } else {
                        SpoilerView(revealed: Binding(
                            get: { !viewModel.isBalanceHidden },
                            set: { viewModel.isBalanceHidden = !$0 }
                        )) {
                            HStack(spacing: 4) {
                                Text(viewModel.balanceText)
                                Text(viewModel.selectedCurrency.symbol)
                            }
                            .foregroundStyle(.black)
                        }
                        .transition(.opacity)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isBalanceHidden)
    }
    
    private func currencyRow(viewModel: BankAccountViewModel) -> some View {
        Button {
            if viewModel.mode == .edit {
                showCurrencyDialog = true
            }
        } label: {
            HStack {
                Text("Валюта")
                Spacer()
                Text(viewModel.selectedCurrency.code)
                    .foregroundStyle(viewModel.mode == .view ? .black : .primary)
                if viewModel.mode == .edit {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func label(for currency: BankAccount.Currency) -> String {
        switch currency {
        case .rub: return "Российский Рубль RUB"
        case .usd: return "Американский Доллар USD"
        case .eur: return "Евро EUR"
        case .other(let code): return code
        }
    }
}


#Preview {
    NavigationStack {
        BankAccountView()
    }
} 
