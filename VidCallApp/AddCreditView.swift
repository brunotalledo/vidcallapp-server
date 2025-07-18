//
//  AddCredit.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/30/25.
//

import SwiftUI
import BraintreeDropIn

struct AddCreditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var braintreeManager = BraintreeManager.shared
    @Binding var amount: String
    let balance: Double
    var onAddCredit: (Double) -> Void
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    @State private var showingPaymentSheet = false

    let keypadButtons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text("Available Balance")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                        Text("$\(String(format: "%.2f", balance))")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 14)

                    Text("$\(amount)")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, 12)

                    VStack(spacing: 14) {
                        ForEach(keypadButtons, id: \.self) { row in
                            HStack(spacing: 14) {
                                ForEach(row, id: \.self) { button in
                                    Button(action: {
                                        handleKeyPress(button)
                                    }) {
                                        if button == "⌫" {
                                            Image(systemName: "delete.left")
                                                .font(.system(size: 22))
                                                .foregroundColor(.white)
                                                .frame(width: 60, height: 60)
                                        } else {
                                            Text(button)
                                                .font(.system(size: 26, weight: .medium))
                                                .foregroundColor(.white)
                                                .frame(width: 60, height: 60)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Button(action: {
                        if let value = Double(amount), value > 0 {
                            processPayment(amount: value)
                        }
                    }) {
                        Text("Add Credits")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(appBlue)
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    .disabled(Double(amount) ?? 0 <= 0 || braintreeManager.isLoading)
                }
                .frame(maxHeight: 520)
            }
            .navigationBarTitle("Add Credit", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(.white)
                    }
                }
            }
            .alert("Payment Error", isPresented: $braintreeManager.showError) {
                Button("OK") { }
            } message: {
                Text(braintreeManager.errorMessage ?? "Unknown error occurred")
            }
        }
    }

    private func handleKeyPress(_ key: String) {
        switch key {
        case "⌫":
            if !amount.isEmpty { amount.removeLast() }
            if amount.isEmpty { amount = "0" }
        case ".":
            if !amount.contains(".") { amount += "." }
        default:
            amount = (amount == "0") ? key : amount + key
        }
    }
    
    private func processPayment(amount: Double) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Dismiss the SwiftUI modal first
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                braintreeManager.showDropIn(amount: String(amount), from: rootViewController) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            // Payment successful - update the UI
                            self.onAddCredit(amount)
                            // Show success message
                            self.showSuccessMessage(amount: amount)
                        } else {
                            // Show error message
                            self.showErrorMessage(error: error ?? "Payment failed")
                        }
                    }
                }
            }
        }
    }
    
    private func showSuccessMessage(amount: Double) {
        // You can implement a custom alert or notification here
        print("✅ Successfully added \(amount) credits!")
        // For now, we'll just print to console
        // In a real app, you might want to show a toast or alert
    }
    
    private func showErrorMessage(error: String) {
        // You can implement a custom alert or notification here
        print("❌ Payment failed: \(error)")
        // For now, we'll just print to console
        // In a real app, you might want to show a toast or alert
    }
}
