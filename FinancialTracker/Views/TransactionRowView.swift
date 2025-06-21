import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let category: Category?

    var body: some View {
        HStack(spacing: 16) {
            categoryIcon
                .frame(width: 22, height: 22)
                .alignmentGuide(.listRowSeparatorLeading) { _ in 38 }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category?.name ?? "Без категории")
                    .lineSpacing(-2)
                
                if let comment = transaction.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(transaction.amount.rubleFormattedNoFraction)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
    
    @ViewBuilder
    private var categoryIcon: some View {
        if let category = category {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.4))
                Text(category.icon)
                    .font(.system(size: 12))
            }
        } else {
            Image(systemName: "questionmark.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    let sampleTransaction = Transaction(
        id: 999,
        accountId: 1,
        categoryId: 1,
        amount: 1234.56,
        transactionDate: Date(),
        comment: "Комментарий",
        creationDate: Date(),
        modificationDate: Date()
    )
    
    return List {
        TransactionRowView(
            transaction: sampleTransaction,
            category: Category(
                id: 1,
                name: "Зарплата",
                icon: "💰",
                direction: .income
            )
        )
        TransactionRowView(
            transaction: sampleTransaction,
            category: Category(
                id: 2,
                name: "Еда",
                icon: "🍔",
                direction: .outcome
            )
        )
    }
} 
