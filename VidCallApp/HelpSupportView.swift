import SwiftUI

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // FAQ Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Frequently Asked Questions")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                HelpRow(
                                    icon: "video.fill",
                                    title: "Video Call Issues",
                                    color: appBlue
                                )
                                
                                HelpRow(
                                    icon: "creditcard.fill",
                                    title: "Payment & Billing",
                                    color: .green
                                )
                                
                                HelpRow(
                                    icon: "person.fill",
                                    title: "Account Settings",
                                    color: .orange
                                )
                            }
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Contact Support Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contact Support")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                HelpRow(
                                    icon: "envelope.fill",
                                    title: "Email Support",
                                    color: .purple
                                )
                                
                                HelpRow(
                                    icon: "message.fill",
                                    title: "Live Chat",
                                    color: .blue
                                )
                            }
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // App Info
                        VStack(spacing: 16) {
                            Text("App Version 1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                // Open terms of service
                            }) {
                                Text("Terms of Service")
                                    .font(.system(size: 14))
                                    .foregroundColor(appBlue)
                            }
                            
                            Button(action: {
                                // Open privacy policy
                            }) {
                                Text("Privacy Policy")
                                    .font(.system(size: 14))
                                    .foregroundColor(appBlue)
                            }
                        }
                        .padding(.top, 24)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct HelpRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Handle help item tap
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
        }
        .background(Color.clear)
    }
}

struct HelpSupportView_Previews: PreviewProvider {
    static var previews: some View {
        HelpSupportView()
            .preferredColorScheme(.dark)
    }
} 