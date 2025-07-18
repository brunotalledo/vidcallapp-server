//
//  Created by Bruno Talledo on 4/11/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PaymentView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var transactions: [TransactionRecord] = []
    @State private var isLoadingTransactions = false
    @State private var showingAddCredit = false
    @State private var showingWithdraw = false
    @State private var showingSetupPayment = false
    @State private var showingSavedPaymentMethods = false
    @State private var creditAmount: String = "10"
    @State private var withdrawAmount: String = "0"

    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    @StateObject private var braintreeManager = BraintreeManager.shared
    
    // Use real balance from user profile
    private var balance: Double {
        guard let userProfile = appViewModel.userProfile else { return 0.0 }
        if userProfile.userType == .provider {
            // Providers see 75% of their credits (receiving balance)
            return Double(userProfile.credits) * 0.75
        } else {
            // Customers see full balance
            return Double(userProfile.credits)
        }
    }
    
    private var balanceLabel: String {
        if let userProfile = appViewModel.userProfile {
            return userProfile.userType == .provider ? "Earnings" : "Credits"
        }
        return "Balance"
    }

    private var viddyLogo: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 80, height: 80)
            Circle()
                .fill(appBlue)
                .frame(width: 56, height: 56)
            Text("V")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .multilineTextAlignment(.center)
        }
        .shadow(color: appBlue.opacity(0.5), radius: 16, x: 0, y: 0)
    }

    private func usernameCard(userProfile: UserProfile) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text("Username")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            HStack(spacing: 4) {
                Text(userProfile.username)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                if userProfile.userType == .provider {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(appBlue)
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 64)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(appBlue, lineWidth: 1)
        )
        .padding(.horizontal, 8)
    }

    private var balanceBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.black.opacity(0.5))
    }

    private var balanceBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(appBlue, lineWidth: 1)
    }

    private var balanceText: some View {
        VStack(spacing: 4) {
            Text(balanceLabel)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Text("$\(String(format: "%.2f", balance))")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var balanceCard: some View {
        ZStack {
            balanceBackground
            balanceBorder
            balanceText
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [appBlue.opacity(0.3), Color.black]),
                    startPoint: .top,
                    endPoint: .center
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 24) {
                    logoSection
                    userInfoSection
                    providerOrCustomerSection
                    transactionHistorySection
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                refreshBalance()
                loadTransactions()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                refreshBalance()
                loadTransactions()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CreditsUpdated"))) { _ in
                refreshBalance()
                loadTransactions()
            }
            .sheet(isPresented: $showingWithdraw) {
                WithdrawView(balance: balance, onWithdraw: { newAmount in
                    // Handle withdrawal logic
                    refreshBalance()
                    loadTransactions()
                })
            }
            .sheet(isPresented: $showingSetupPayment) {
                SetupPaymentView()
            }
            .sheet(isPresented: $showingSavedPaymentMethods) {
                SavedPaymentMethodsView()
            }
            .sheet(isPresented: $showingAddCredit) {
                AddCreditView(amount: $creditAmount, balance: balance) { addedAmount in
                    // Refresh balance and transactions after successful payment
                    refreshBalance()
                    loadTransactions()
                }
                .environmentObject(appViewModel)
            }
            .sheet(isPresented: $appViewModel.showingRateEditSheet) {
                if let userProfile = appViewModel.userProfile {
                    RateEditView(
                        currentRate: userProfile.ratePerMinute,
                        currentSessionRate: userProfile.sessionRate,
                        currentBillingMode: userProfile.billingMode,
                        onSave: { newRatePerMinute, newSessionRate, newBillingMode in
                            // Update all rate fields and billing mode in Firestore
                            let db = Firestore.firestore()
                            db.collection("users").document(userProfile.uid).updateData([
                                "ratePerMinute": newRatePerMinute,
                                "sessionRate": newSessionRate as Any,
                                "billingMode": newBillingMode.rawValue
                            ]) { error in
                                if let error = error {
                                    print("❌ Failed to update rates: \(error.localizedDescription)")
                                } else {
                                    print("✅ Rates updated: $\(newRatePerMinute)/min, $\(newSessionRate ?? 0)/session, mode: \(newBillingMode.rawValue)")
                                    appViewModel.fetchUserProfile(for: userProfile.uid)
                                }
                            }
                            appViewModel.showingRateEditSheet = false
                        },
                        onCancel: {
                            appViewModel.showingRateEditSheet = false
                        }
                    )
                }
            }
        }
    }
    
    private var logoSection: some View {
        VStack(spacing: 12) {
            viddyLogo
            Text("VIDDYCALL")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(appBlue)
                .shadow(color: appBlue.opacity(0.5), radius: 8, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 16)
    }

    private var userInfoSection: some View {
        VStack(spacing: 16) {
            if let userProfile = appViewModel.userProfile {
                usernameCard(userProfile: userProfile)
                    .frame(maxWidth: .infinity)
            }
            BalanceCardView(balanceLabel: balanceLabel, balance: balance, appBlue: appBlue)
                .frame(maxWidth: .infinity)
            if let userProfile = appViewModel.userProfile, userProfile.userType == .provider {
                RatePerMinuteCard(
                    userProfile: userProfile,
                    appBlue: appBlue,
                    showingRateEditSheet: $appViewModel.showingRateEditSheet,
                    onBillingModeChange: { newMode in
                        let db = Firestore.firestore()
                        db.collection("users").document(userProfile.uid).updateData([
                            "billingMode": newMode.rawValue
                        ]) { error in
                            if let error = error {
                                print("❌ Failed to update billing mode: \(error.localizedDescription)")
                            } else {
                                print("✅ Billing mode updated to: \(newMode.rawValue)")
                                appViewModel.fetchUserProfile(for: userProfile.uid)
                            }
                        }
                    }
                )
                .frame(maxWidth: .infinity)
                billingModeSection(userProfile: userProfile)
                availabilitySection(userProfile: userProfile)
            }
        }
        .padding(.horizontal, 24)
    }

    private func billingModeSection(userProfile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Billing Mode:")
                .font(.caption)
                .foregroundColor(.white)
            HStack(spacing: 0) {
                ForEach([BillingMode.perMinute, BillingMode.perSession], id: \.self) { mode in
                    Button(action: {
                        if userProfile.billingMode != mode {
                            let db = Firestore.firestore()
                            db.collection("users").document(userProfile.uid).updateData([
                                "billingMode": mode.rawValue
                            ]) { error in
                                if let error = error {
                                    print("❌ Failed to update billing mode: \(error.localizedDescription)")
                                } else {
                                    print("✅ Billing mode updated to: \(mode.rawValue)")
                                    appViewModel.fetchUserProfile(for: userProfile.uid)
                                }
                            }
                        }
                    }) {
                        Text(mode == .perMinute ? "Per Minute" : "Per Session")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(mode == userProfile.billingMode ? appBlue : Color.black)
                            .foregroundColor(mode == userProfile.billingMode ? .black : appBlue)
                            .cornerRadius(mode == userProfile.billingMode ? 8 : 0)
                    }
                }
            }
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(appBlue, lineWidth: 2)
            )
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    private func availabilitySection(userProfile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Availability")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("Accept incoming calls")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get: { userProfile.isAvailable },
                    set: { newValue in
                        updateAvailability(isAvailable: newValue)
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: appBlue))
            }
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

    private var providerOrCustomerSection: some View {
        Group {
            if let userProfile = appViewModel.userProfile, userProfile.userType == .provider {
                ProviderUISection(showingWithdraw: $showingWithdraw, appBlue: appBlue)
            } else {
                CustomerUISection(showingAddCredit: $showingAddCredit, appBlue: appBlue, braintreeManager: braintreeManager)
            }
        }
    }

    private var transactionHistorySection: some View {
        Group {
            if let userProfile = appViewModel.userProfile, userProfile.userType != .provider {
                TransactionHistorySection(
                    transactions: transactions,
                    isLoadingTransactions: isLoadingTransactions,
                    isCustomer: true,
                    formatTransactionDate: formatTransactionDate
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private func refreshBalance() {
        if let user = Auth.auth().currentUser {
            appViewModel.fetchUserProfile(for: user.uid)
        }
    }
    
    private func loadTransactions() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoadingTransactions = true
        let db = Firestore.firestore()
        
        print("🔍 Loading transactions for user: \(user.uid)")
        
        db.collection("transactions")
            .whereField("userId", isEqualTo: user.uid)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoadingTransactions = false
                    
                    if let error = error {
                        print("❌ Error loading transactions: \(error.localizedDescription)")
                        return
                    }
                    
                    print("📦 Found \(snapshot?.documents.count ?? 0) transaction documents")
                    
                    let transactions = snapshot?.documents.compactMap { document -> TransactionRecord? in
                        let data = document.data()
                        let username = data["username"] as? String ?? ""
                        let relatedUsername = data["relatedUsername"] as? String ?? ""
                        print("📄 Transaction data: \(data)")
                        print("👤 Username from transaction: '\(username)'")
                        return TransactionRecord(
                            id: document.documentID,
                            amount: data["amount"] as? Double ?? 0.0,
                            paymentType: data["paymentType"] as? String ?? "",
                            status: data["status"] as? String ?? "",
                            timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                            username: username,
                            relatedUsername: relatedUsername,
                            callDuration: data["callDuration"] as? Int ?? 0,
                            callRate: data["callRate"] as? Double
                        )
                    } ?? []
                    
                    // Sort by timestamp in descending order (most recent first)
                    self.transactions = transactions.sorted { $0.timestamp > $1.timestamp }
                    
                    print("✅ Loaded \(self.transactions.count) transactions")
                }
            }
    }
    
    private func getTransactionType(_ paymentType: String) -> String {
        switch paymentType {
        case "credit_purchase":
            return "Added Credit"
        case "call_payment":
            return "Video Call"
        case "withdrawal":
            return "Withdrawal"
        case "call_earnings":
            return "Call Earnings"
        default:
            return paymentType.capitalized
        }
    }
    
    private func formatTransactionAmount(_ amount: Double, _ paymentType: String) -> String {
        let prefix = amount >= 0 ? "+" : ""
        return "\(prefix)$\(String(format: "%.2f", abs(amount)))"
    }
    
    private func formatTransactionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "Today, h:mm a"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "Yesterday, h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: date)
    }
    
    private func updateAvailability(isAvailable: Bool) {
        guard let userProfile = appViewModel.userProfile else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userProfile.uid).updateData([
            "isAvailable": isAvailable
        ]) { error in
            if let error = error {
                print("❌ Failed to update availability: \(error.localizedDescription)")
            } else {
                print("✅ Availability updated to: \(isAvailable ? "Available" : "Unavailable")")
                // Refresh the user profile to reflect the change
                appViewModel.fetchUserProfile(for: userProfile.uid)
            }
        }
    }
}

struct PaymentView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentView()
            .preferredColorScheme(.dark)
            .environmentObject(AppViewModel())
    }
}
