import SwiftUI

struct PayoutHistoryView: View {
    @StateObject private var paypalManager = PayPalPayoutsManager.shared
    @State private var payouts: [PayoutRecord] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: appBlue))
                                .scaleEffect(1.2)
                            Text("Loading payout history...")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        }
                    } else if payouts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Payout History")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("Your payout history will appear here once you make withdrawals.")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        List {
                            ForEach(payouts) { payout in
                                PayoutRowView(payout: payout)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(PlainListStyle())
                        .background(Color.clear)
                    }
                }
            }
            .navigationTitle("Payout History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadPayoutHistory()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(appBlue)
                    }
                }
            }
        }
        .onAppear {
            loadPayoutHistory()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadPayoutHistory() {
        isLoading = true
        paypalManager.getPayoutHistory { payouts in
            DispatchQueue.main.async {
                self.isLoading = false
                if let payouts = payouts {
                    self.payouts = payouts
                } else {
                    self.errorMessage = "Failed to load payout history"
                    self.showError = true
                }
            }
        }
    }
}

struct PayoutRowView: View {
    let payout: PayoutRecord
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(payout.formattedAmount)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(payout.paypalEmail)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: payout.status)
                    
                    Text(payout.formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            if !payout.payoutId.isEmpty {
                HStack {
                    Text("Payout ID:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(payout.payoutId)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "completed":
            return .green
        case "pending":
            return .orange
        case "failed":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        Text(status.capitalized)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }
}

#Preview {
    PayoutHistoryView()
} 