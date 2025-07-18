import SwiftUI

struct ProviderUISection: View {
    @Binding var showingWithdraw: Bool
    let appBlue: Color
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showPayPalEmailSheet = false
    @State private var localPayPalEmail: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                showingWithdraw = true
            }) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Withdraw")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(appBlue)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .disabled(appViewModel.userProfile?.paypalEmail?.isEmpty ?? true)
            .opacity((appViewModel.userProfile?.paypalEmail?.isEmpty ?? true) ? 0.5 : 1.0)

            VStack(alignment: .leading, spacing: 8) {
                Text("PayPal Account")
                    .font(.headline)
                    .foregroundColor(.white)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 60)
                    .overlay(
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(appBlue)
                            if let email = appViewModel.userProfile?.paypalEmail, !email.isEmpty {
                                Text(email)
                                    .foregroundColor(.white)
                                    .font(.system(size: 15))
                                Spacer()
                                Button(action: { showPayPalEmailSheet = true }) {
                                    Text("Edit")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(appBlue)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(6)
                                }
                            } else {
                                Text("Add your PayPal email to enable withdrawals")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 15))
                                Spacer()
                                Button(action: { showPayPalEmailSheet = true }) {
                                    Text("Add")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(appBlue)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.horizontal)
                    )
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showPayPalEmailSheet) {
            PayPalEmailEditSheet(currentEmail: appViewModel.userProfile?.paypalEmail) { newEmail in
                localPayPalEmail = newEmail
                appViewModel.fetchUserProfile(for: appViewModel.userProfile?.uid ?? "")
            }
        }
    }
} 