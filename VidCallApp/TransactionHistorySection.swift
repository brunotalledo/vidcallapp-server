import SwiftUI

struct TransactionHistorySection: View {
    let transactions: [TransactionRecord]
    let isLoadingTransactions: Bool
    let isCustomer: Bool // NEW: pass this from PaymentView
    let formatTransactionDate: (Date) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(isCustomer ? "Call History" : "Transaction History")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if isLoadingTransactions {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)

            if filteredCalls.isEmpty && !isLoadingTransactions {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 28))
                        .foregroundColor(.gray)
                    Text(isCustomer ? "No calls yet" : "No transactions yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    Text(isCustomer ? "Your call history will appear here" : "Your transaction history will appear here")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCalls) { transaction in
                            CallHistoryRow(
                                username: transaction.relatedUsername,
                                date: formatTransactionDate(transaction.timestamp),
                                duration: transaction.callDuration ?? 0
                            )
                            .font(.system(size: 13))
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // Only show call transactions for customers
    private var filteredCalls: [TransactionRecord] {
        if isCustomer {
            return transactions.filter { $0.paymentType == "call_payment" }
        } else {
            return transactions
        }
    }
}

// New row for call history (customer)
struct CallHistoryRow: View {
    let username: String
    let date: String
    let duration: Int
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("@" + (username.isEmpty ? "Unknown" : username))
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(appBlue)
                        .font(.system(size: 14, weight: .bold))
                }
                HStack(spacing: 8) {
                    Text(formatDuration(duration))
                        .foregroundColor(.white)
                        .font(.system(size: 13))
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 13, weight: .bold))
                    Text(date)
                        .foregroundColor(Color.white.opacity(0.7))
                        .font(.system(size: 13))
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.13))
        .cornerRadius(10)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%dm %02ds", m, s)
    }
} 