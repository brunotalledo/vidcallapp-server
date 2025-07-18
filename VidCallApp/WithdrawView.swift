//
//  WithdrawView.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/30/25.
//

import SwiftUI

struct WithdrawView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @StateObject private var paypalManager = PayPalPayoutsManager.shared
    @State private var amount: String = "0"
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    let balance: Double
    var onWithdraw: (Double) -> Void
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)

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

                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("Available Balance")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                        Text("$\(String(format: "%.2f", balance))")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 10)

                    Text("$\(amount)")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Withdraw to PayPal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        if let email = appViewModel.userProfile?.paypalEmail, !email.isEmpty {
                            Text(email)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        } else {
                            Text("No PayPal email set. Please add your PayPal email in the profile section.")
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 8)

                    VStack(spacing: 12) {
                        ForEach(keypadButtons, id: \.self) { row in
                            HStack(spacing: 12) {
                                ForEach(row, id: \.self) { button in
                                    Button(action: {
                                        handleKeyPress(button)
                                    }) {
                                        if button == "⌫" {
                                            Image(systemName: "delete.left")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .frame(width: 60, height: 60)
                                        } else {
                                            Text(button)
                                                .font(.system(size: 26, weight: .medium))
                                                .foregroundColor(.white)
                                                .frame(width: 60, height: 60)
                                        }
                                    }
                                    .background(Color.white.opacity(0.07))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)

                    Spacer(minLength: 8)

                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal)

                    Button(action: {
                        requestWithdrawal()
                    }) {
                        if paypalManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Text("Confirm Withdrawal")
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(appBlue)
                                .foregroundColor(.black)
                                .cornerRadius(14)
                        }
                    }
                    .disabled(Double(amount) ?? 0 > balance || Double(amount) ?? 0 <= 0 || (appViewModel.userProfile?.paypalEmail?.isEmpty ?? true) || paypalManager.isLoading)
                    .opacity((Double(amount) ?? 0 > balance || Double(amount) ?? 0 <= 0 || (appViewModel.userProfile?.paypalEmail?.isEmpty ?? true) || paypalManager.isLoading) ? 0.5 : 1.0)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
            .navigationBarTitle("Withdraw to PayPal", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(.white)
                    }
                }
            }
            .alert("Withdrawal Successful", isPresented: $showSuccessAlert) {
                Button("OK") { 
                    dismiss()
                }
            } message: {
                Text("Your withdrawal request has been submitted. You will receive the funds in your PayPal account within 1-3 business days.")
            }
            .alert("Withdrawal Failed", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
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
            if let newVal = Double(amount + key), newVal <= balance {
                amount = (amount == "0") ? key : amount + key
            }
        }
    }
    
    private func requestWithdrawal() {
        guard let paypalEmail = appViewModel.userProfile?.paypalEmail, !paypalEmail.isEmpty else {
            errorMessage = "No PayPal email set. Please add your PayPal email in the profile section."
            showErrorAlert = true
            return
        }
        
        guard let withdrawalAmount = Double(amount), withdrawalAmount > 0 else {
            errorMessage = "Please enter a valid amount"
            showErrorAlert = true
            return
        }
        
        guard withdrawalAmount <= balance else {
            errorMessage = "Insufficient balance"
            showErrorAlert = true
            return
        }
        
        paypalManager.requestPayout(amount: withdrawalAmount, paypalEmail: paypalEmail) { success, error in
            if success {
                showSuccessAlert = true
                onWithdraw(withdrawalAmount)
            } else {
                errorMessage = error ?? "Withdrawal failed"
                showErrorAlert = true
            }
        }
    }
}
