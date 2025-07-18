import SwiftUI

struct SavedPaymentMethodsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var braintreeManager = BraintreeManager.shared
    @State private var showingAddPayment = false
    @State private var showingDeleteAlert = false
    @State private var paymentMethodToDelete: PaymentMethod?
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if braintreeManager.savedPaymentMethods.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No Saved Payment Methods")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Add a payment method to make quick and secure payments.")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 60)
                        
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(braintreeManager.savedPaymentMethods) { paymentMethod in
                                    PaymentMethodRow(
                                        paymentMethod: paymentMethod,
                                        onDelete: {
                                            paymentMethodToDelete = paymentMethod
                                            showingDeleteAlert = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Button("Add Payment Method") {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootViewController = window.rootViewController {
                            
                            // Dismiss the current sheet first
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                braintreeManager.showDropInForSetup(from: rootViewController) { success, error in
                                    if success {
                                        // Refresh the saved payment methods
                                        braintreeManager.fetchSavedPaymentMethods { _ in }
                                    }
                                }
                            }
                        }
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(appBlue)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .navigationTitle("Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(appBlue)
                }
            }
            .onAppear {
                braintreeManager.fetchSavedPaymentMethods { _ in
                    // Payment methods are automatically updated in the @Published property
                }
            }
            .alert("Delete Payment Method", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let paymentMethod = paymentMethodToDelete {
                        deletePaymentMethod(paymentMethod)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this payment method?")
            }
        }
    }
    
    private func deletePaymentMethod(_ paymentMethod: PaymentMethod) {
        braintreeManager.deletePaymentMethod(token: paymentMethod.id) { success in
            if success {
                // Refresh the list
                braintreeManager.fetchSavedPaymentMethods { _ in }
            }
        }
    }
}

struct PaymentMethodRow: View {
    let paymentMethod: PaymentMethod
    let onDelete: () -> Void
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(paymentMethod.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    if paymentMethod.isDefault {
                        Text("Default")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(appBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(appBlue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                if !paymentMethod.expirationDisplay.isEmpty {
                    Text("Expires \(paymentMethod.expirationDisplay)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
} 