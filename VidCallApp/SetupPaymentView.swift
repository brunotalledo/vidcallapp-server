//
//  SetupPaymentView.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/30/25.
//

import SwiftUI
import BraintreeDropIn

struct SetupPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var braintreeManager = BraintreeManager.shared
    @State private var isLoading = false
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 40) {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 48))
                            .foregroundColor(appBlue)
                        
                        Text("Setup Payment Method")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Add your preferred payment method to make quick and secure payments for video calls.")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: appBlue))
                        } else {
                            Button("Add Payment Method") {
                                setupPaymentMethod()
                            }
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(appBlue)
                            .foregroundColor(.black)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Setup Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(.white)
                    }
                }
            }
            .alert("Payment Setup Error", isPresented: $braintreeManager.showError) {
                Button("OK") { }
            } message: {
                Text(braintreeManager.errorMessage ?? "Unknown error occurred")
            }
        }
    }

    func setupPaymentMethod() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // Dismiss the SwiftUI modal first
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                braintreeManager.showDropInForSetup(from: rootViewController) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            // Payment method was successfully added
                            // No need to dismiss again
                        }
                    }
                }
            }
        }
    }
}
