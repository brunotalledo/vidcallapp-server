import SwiftUI
import FirebaseFirestore
import UniformTypeIdentifiers

struct ActivityView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var transactions: [TransactionRecord] = []
    @State private var isLoading = false
    @State private var monthlyTotal: Double = 0.0
    @State private var showShareSheet = false
    @State private var showFileExporter = false
    @State private var csvString: String = ""
    @State private var showCSVError = false
    @State private var csvErrorMessage = ""
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Activity")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Spacer()
                        if isProvider {
                            Button(action: exportCSV) {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.title2)
                                    Text("Download Transactions")
                                        .font(.subheadline.bold())
                                }
                                .foregroundColor(appBlue)
                            }
                            .padding(.trailing)
                        }
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    
                    // Monthly Total for Providers Only
                    if let userProfile = appViewModel.userProfile, userProfile.userType == .provider {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly Earnings")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("This Month")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                    
                                    Text("$\(String(format: "%.2f", monthlyTotal))")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 32))
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    if isLoading {
                        ProgressView().padding()
                    } else if transactions.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No calls yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredTransactions) { tx in
                                ActivityCallCard(transaction: tx)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteTransaction(tx)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        .tint(.red)
                                    }
                                    .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.clear)
                    }
                }
            }
            .onAppear(perform: loadTransactions)
            .fileExporter(
                isPresented: $showFileExporter,
                document: CSVDocument(csv: csvString),
                contentType: .commaSeparatedText,
                defaultFilename: "ProviderEarnings.csv"
            ) { result in
                switch result {
                case .success:
                    print("✅ CSV file exported successfully.")
                case .failure(let error):
                    print("❌ File export error: \(error.localizedDescription)")
                    self.csvErrorMessage = "File export error: \(error.localizedDescription)"
                    self.showCSVError = true
                }
            }
            .alert("CSV Export Error", isPresented: $showCSVError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(csvErrorMessage)
            }
        }
    }
    
    private var isProvider: Bool {
        appViewModel.userProfile?.userType == .provider
    }

    private func loadTransactions() {
        guard let user = appViewModel.userProfile else { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("transactions")
            .whereField("userId", isEqualTo: user.uid)
            .whereField("paymentType", in: ["call_payment", "call_earnings"])
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        print("❌ Error loading transactions: \(error.localizedDescription)")
                        return
                    }
                    let txs = snapshot?.documents.compactMap { doc -> TransactionRecord? in
                        let data = doc.data()
                        return TransactionRecord(
                            id: doc.documentID,
                            amount: data["amount"] as? Double ?? 0.0,
                            paymentType: data["paymentType"] as? String ?? "",
                            status: data["status"] as? String ?? "",
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                            username: data["username"] as? String ?? "",
                            relatedUsername: data["relatedUsername"] as? String ?? "",
                            callDuration: data["callDuration"] as? Int ?? 0,
                            callRate: data["callRate"] as? Double
                        )
                    } ?? []
                    self.transactions = txs
                    
                    // Calculate monthly total for providers
                    if let userProfile = self.appViewModel.userProfile, userProfile.userType == .provider {
                        self.calculateMonthlyTotal(from: txs)
                    }
                }
            }
    }
    
    private func calculateMonthlyTotal(from transactions: [TransactionRecord]) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        let monthlyEarnings = transactions
            .filter { transaction in
                transaction.paymentType == "call_earnings" &&
                (calendar.isDate(transaction.timestamp, inSameDayAs: startOfMonth) ||
                 transaction.timestamp >= startOfMonth)
            }
            .reduce(0.0) { total, transaction in
                total + transaction.amount
            }
        
        self.monthlyTotal = monthlyEarnings
    }

    private func deleteTransaction(_ tx: TransactionRecord) {
        let db = Firestore.firestore()
        db.collection("transactions").document(tx.id).delete { error in
            if let error = error {
                print("❌ Error deleting transaction: \(error.localizedDescription)")
            } else {
                print("✅ Transaction deleted: \(tx.id)")
                // Remove from local list
                transactions.removeAll { $0.id == tx.id }
            }
        }
    }

    private func exportCSV() {
        // Only export provider's call_earnings transactions
        let exportTxs = transactions.filter { $0.paymentType == "call_earnings" }
        var csv = "Date/Time,Customer Username,Call Duration,Rate,Amount/Earnings\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        for tx in exportTxs {
            let dateStr = dateFormatter.string(from: tx.timestamp)
            let customer = tx.relatedUsername
            let duration = tx.callDuration ?? 0
            let rate = tx.callRate ?? 0
            let amount = tx.amount
            let row = "\(dateStr),@\(customer),\(duration)s,$\(String(format: "%.2f", rate)),$\(String(format: "%.2f", amount))\n"
            csv.append(row)
        }
        self.csvString = csv
        if !csv.isEmpty {
            self.showFileExporter = true
        } else {
            self.csvErrorMessage = "CSV data is empty."
            self.showCSVError = true
        }
    }

    // Add this computed property to filter transactions
    private var filteredTransactions: [TransactionRecord] {
        guard let userProfile = appViewModel.userProfile else { return [] }
        if userProfile.userType == .provider {
            return transactions.filter { $0.paymentType == "call_earnings" }
        } else {
            return transactions.filter { $0.paymentType == "call_payment" }
        }
    }
}

struct ActivityCallCard: View {
    let transaction: TransactionRecord
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("@" + (otherPartyUsername.isEmpty ? "Unknown" : otherPartyUsername))
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(appBlue)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text(formatDate(transaction.timestamp))
                    .foregroundColor(Color.white.opacity(0.7))
                    .font(.system(size: 13))
            }
            HStack(spacing: 8) {
                if let duration = transaction.callDuration, duration > 0 {
                    Text(formatDuration(duration))
                        .foregroundColor(.white)
                        .font(.system(size: 13))
                }
                if let rate = transaction.callRate, rate > 0 {
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 13, weight: .bold))
                    Text(String(format: "$%.2f/min", rate))
                        .foregroundColor(.white)
                        .font(.system(size: 13))
                }
                if transaction.amount != 0 {
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 13, weight: .bold))
                    Text(amountText)
                        .foregroundColor(transaction.amount < 0 ? .red : .green)
                        .font(.system(size: 13, weight: .semibold))
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.13))
        .cornerRadius(12)
    }

    // Show the other party's username (for customer, show provider; for provider, show customer)
    private var otherPartyUsername: String {
        if transaction.amount < 0 {
            // Customer paid, show relatedUsername (provider)
            return transaction.relatedUsername
        } else {
            // Provider earned, show relatedUsername (customer)
            return transaction.relatedUsername
        }
    }

    private var amountText: String {
        if transaction.amount < 0 {
            return String(format: "- $%.2f", abs(transaction.amount))
        } else {
            return String(format: "+ $%.2f", transaction.amount)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy h:mm a"
        return formatter.string(from: date)
    }
    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%dm %02ds", m, s)
    }
}

// CSVDocument for fileExporter
import Foundation
import UniformTypeIdentifiers
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var csv: String
    init(csv: String) { self.csv = csv }
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents, let str = String(data: data, encoding: .utf8) {
            self.csv = str
        } else {
            self.csv = ""
        }
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = csv.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
