import SwiftUI

struct SettingsView: View {
    @State private var showChangePassword = false
    @State private var showNotificationPrefs = false
    @State private var showPaymentMethods = false
    @State private var showDeleteAccount = false
    @State private var showLogout = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var showVersion = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Account").font(.headline)) {
                    Button("Change Password / Login Info") { showChangePassword = true }
                        .font(.system(size: 18, weight: .medium))
                    Button("Delete Account") { showDeleteAccount = true }
                        .font(.system(size: 18, weight: .medium))
                    Button("Logout") { showLogout = true }
                        .font(.system(size: 18, weight: .medium))
                }
                Section(header: Text("Notifications").font(.headline)) {
                    Button("Notification Preferences") { showNotificationPrefs = true }
                        .font(.system(size: 18, weight: .medium))
                }
                Section(header: Text("Payments").font(.headline)) {
                    Button("Manage Payment Methods") { showPaymentMethods = true }
                        .font(.system(size: 18, weight: .medium))
                }
                Section(header: Text("Legal").font(.headline)) {
                    Button("Terms of Service") { showTerms = true }
                        .font(.system(size: 18, weight: .medium))
                    Button("Privacy Policy") { showPrivacy = true }
                        .font(.system(size: 18, weight: .medium))
                }
                Section(header: Text("About").font(.headline)) {
                    Button("App Version Info") { showVersion = true }
                        .font(.system(size: 18, weight: .medium))
                }
            }
            .navigationTitle("Settings")
            .alert("Change Password / Login Info", isPresented: $showChangePassword) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This is a placeholder for changing your password or login info.")
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
            .alert("Delete Account", isPresented: $showDeleteAccount) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This is a placeholder for deleting your account.")
            }
            .alert("Logout", isPresented: $showLogout) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This is a placeholder for logging out.")
            }
            .alert("Terms of Service", isPresented: $showTerms) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This is a placeholder for the Terms of Service.")
            }
            .alert("Privacy Policy", isPresented: $showPrivacy) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This is a placeholder for the Privacy Policy.")
            }
            .alert("App Version Info", isPresented: $showVersion) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("App Version 1.0.0 (placeholder)")
            }
        }
    }
}

#Preview {
    SettingsView()
} 