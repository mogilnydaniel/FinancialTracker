import SwiftUI

struct BalanceDisplay: View {
    @Binding var isEdit: Bool
    @Binding var text: String
    @FocusState var focused: Bool
    let currencySymbol: String
    let onTextChange: (String) -> Void
    var body: some View {
        HStack(spacing: 4) {
            if isEdit {
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($focused)
                    .onChange(of: text) { onTextChange($0) }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.opacity)
            } else {
                SpoilerView(revealed: .constant(false)) { EmptyView() }
            }
        }
        .frame(height: 44)
    }
} 