//
//  Untitled.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/28/25.
//



import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showingLogoutAlert = false
    @State private var showingRateEditSheet = false
    @State private var showChangePassword = false
    @State private var resetPasswordMessage: String? = nil
    @State private var resetPasswordError: String? = nil
    @State private var showNotificationPrefs = false
    @State private var showPaymentMethods = false
    @State private var showLogout = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showVersion = false
    @State private var showPayoutHistory = false
    
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [appBlue.opacity(0.5), Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 20)
                        // Settings Section (inlined from SettingsView)
                        VStack(spacing: 0) {
                            settingsSectionHeader("Account")
                            settingsButton("Change Password / Login Info") { showChangePassword = true }
                            settingsButton("Logout") { showLogout = true }
                            settingsSectionHeader("Notifications")
                            settingsButton("Notification Preferences") { showNotificationPrefs = true }
                            settingsSectionHeader("Payments")
                            settingsButton("Manage Payment Methods") { showPaymentMethods = true }
                            if let userProfile = viewModel.userProfile, userProfile.userType == .provider {
                                settingsButton("Payout History") { showPayoutHistory = true }
                            }
                            settingsSectionHeader("Legal")
                            settingsButton("Terms of Service") { showTerms = true }
                            settingsButton("Privacy Policy") { showPrivacy = true }
                            settingsSectionHeader("About")
                            settingsButton("App Version Info") { showVersion = true }
                        }
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        // Show different content based on user type
                        if let userProfile = viewModel.userProfile {
                            if userProfile.userType == .provider {
                                VStack(spacing: 16) {
                                    // Show both rates
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Per-Minute Rate")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            Text("$\(String(format: "%.2f", userProfile.ratePerMinute))/min")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        Spacer()
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Per-Session Rate")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                            if let sessionRate = userProfile.sessionRate {
                                                Text("$\(String(format: "%.2f", sessionRate))/session")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.white)
                                            } else {
                                                Text("Not set")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                    // Billing mode switch
                                    HStack {
                                        Text("Billing Mode:")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Spacer()
                                        Toggle(isOn: Binding<Bool>(
                                            get: { userProfile.billingMode == .perMinute },
                                            set: { isPerMinute in
                                                let newMode: BillingMode = isPerMinute ? .perMinute : .perSession
                                                if let uid = userProfile.uid as String? {
                                                    let db = Firestore.firestore()
                                                    db.collection("users").document(uid).updateData([
                                                        "billingMode": newMode.rawValue
                                                    ]) { error in
                                                        if let error = error {
                                                            print("❌ Failed to update billing mode: \(error.localizedDescription)")
                                                        } else {
                                                            print("✅ Billing mode updated to: \(newMode.rawValue)")
                                                            viewModel.fetchUserProfile(for: uid)
                                                        }
                                                    }
                                                }
                                            }
                                        )) {
                                            Text(userProfile.billingMode == .perMinute ? "Per Minute" : "Per Session")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .medium))
                                        }
                                        .toggleStyle(SwitchToggleStyle(tint: appBlue))
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                                    // Edit button
                                    Button(action: { showingRateEditSheet = true }) {
                                        Text("Edit Rates")
                                            .foregroundColor(appBlue)
                                            .font(.system(size: 16, weight: .bold))
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                    }
                                    .padding(.top, 8)
                                }
                                .padding(.horizontal)
                            } else {
                                // CustomerProfileView removed
                            }
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if let user = viewModel.userProfile?.uid {
                viewModel.fetchUserProfile(for: user)
            }
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                viewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .sheet(isPresented: $showingRateEditSheet) {
            if let userProfile = viewModel.userProfile {
                RateEditView(
                    currentRate: userProfile.ratePerMinute,
                    currentSessionRate: userProfile.sessionRate,
                    currentBillingMode: userProfile.billingMode,
                    onSave: { newRatePerMinute, newSessionRate, newBillingMode in
                        // Update all rate fields and billing mode in Firestore
                        if let uid = viewModel.userProfile?.uid {
                            let db = Firestore.firestore()
                            db.collection("users").document(uid).updateData([
                                "ratePerMinute": newRatePerMinute,
                                "sessionRate": newSessionRate as Any,
                                "billingMode": newBillingMode.rawValue
                            ]) { error in
                                if let error = error {
                                    print("❌ Failed to update rates: \(error.localizedDescription)")
                                } else {
                                    print("✅ Rates updated: $\(newRatePerMinute)/min, $\(newSessionRate ?? 0)/session, mode: \(newBillingMode.rawValue)")
                                    viewModel.fetchUserProfile(for: uid)
                                }
                            }
                        }
                        showingRateEditSheet = false
                    },
                    onCancel: {
                        showingRateEditSheet = false
                    }
                )
            }
        }
        // Alerts for settings actions
        .sheet(isPresented: $showChangePassword) {
            ResetPasswordSheet(
                email: viewModel.userProfile?.email ?? "",
                onSend: { email, completion in
                    Auth.auth().sendPasswordReset(withEmail: email) { error in
                        if let error = error {
                            completion(false, error.localizedDescription)
                        } else {
                            completion(true, nil)
                        }
                    }
                }
            )
        }
        .alert("Notification Preferences", isPresented: $showNotificationPrefs) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This is a placeholder for notification preferences.")
        }
        .alert("Manage Payment Methods", isPresented: $showPaymentMethods) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This is a placeholder for managing payment methods.")
        }
        .alert("Logout", isPresented: $showLogout) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                viewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .sheet(isPresented: $showTerms) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .alert("App Version Info", isPresented: $showVersion) {
            Button("OK", role: .cancel) { }
        } message: {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
            Text("App Version \(version) (\(build))")
        }
        .sheet(isPresented: $showPayoutHistory) {
            PayoutHistoryView()
        }
    }
}

// Customer Profile View
struct CustomerProfileView: View {
    let userProfile: UserProfile
    @EnvironmentObject var viewModel: AppViewModel
    
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        VStack(spacing: 16) {
            // Balance Section (removed duplicate)
        }
    }
}

// Provider Profile View
struct ProviderProfileView: View {
    let userProfile: UserProfile
    @Binding var showingRateEditSheet: Bool
    @EnvironmentObject var viewModel: AppViewModel
    
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        VStack(spacing: 16) {
            // Receiving Balance Section
            VStack(alignment: .leading, spacing: 4) {
                Text("Receiving Balance")
                    .foregroundColor(.gray)
                    .font(.caption)
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.green)
                    Text("$\(String(format: "%.2f", userProfile.credits * 0.75))")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
}

private func settingsSectionHeader(_ title: String) -> some View {
    HStack {
        Text(title)
            .font(.headline)
            .foregroundColor(.gray)
        Spacer()
    }
    .padding(.top, 16)
    .padding(.bottom, 4)
    .padding(.horizontal, 8)
}

private func settingsButton(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Color.clear)
    }
    .buttonStyle(PlainButtonStyle())
}

struct ResetPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    let email: String
    var onSend: (String, @escaping (Bool, String?) -> Void) -> Void
    @State private var isSending = false
    @State private var message: String? = nil
    @State private var error: String? = nil
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Reset Password")
                    .font(.title2.bold())
                    .padding(.top)
                Text("We will send a password reset email to:")
                    .foregroundColor(.gray)
                Text(email)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                Button(action: {
                    isSending = true
                    onSend(email) { success, errMsg in
                        isSending = false
                        if success {
                            message = "Password reset email sent!"
                            error = nil
                        } else {
                            message = nil
                            error = errMsg ?? "Unknown error"
                        }
                    }
                }) {
                    if isSending {
                        ProgressView()
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Send Password Reset Email")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(isSending)
                if let message = message {
                    Text(message)
                        .foregroundColor(.green)
                        .font(.body)
                }
                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.body)
                }
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0, green: 0.8, blue: 1.0))
                    }
                }
            }
        }
    }
}

