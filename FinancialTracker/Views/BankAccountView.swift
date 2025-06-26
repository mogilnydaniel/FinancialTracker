import SwiftUI

struct BankAccountView: View {
    @State private var viewModel: BankAccountViewModel?
    @FocusState private var balanceFocused: Bool
    @State private var showCurrencyDialog = false
    
    @Environment(\.di) private var di
    
    private enum Const {
        static let spoilerBlur: CGFloat = 6
        static let animationDuration = 0.25
    }
    
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
