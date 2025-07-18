import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pushNotificationsEnabled = true
    @State private var emailNotificationsEnabled = true
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Notification Settings
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Notification Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            NotificationToggleRow(
                                title: "Push Notifications",
                                isOn: $pushNotificationsEnabled
                            )
                            
                            NotificationToggleRow(
                                title: "Email Notifications",
                                isOn: $emailNotificationsEnabled
                            )
                        }
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Notifications")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct NotificationToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .foregroundColor(.white)
        }
        .toggleStyle(SwitchToggleStyle(tint: appBlue))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NotificationsView()
} 