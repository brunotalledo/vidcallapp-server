import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Privacy Policy")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Text("At ViddyCall, your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use our mobile application and website located at viddycall.com (collectively, the \"Service\").")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            privacySection(
                                title: "1. Information We Collect",
                                content: "Account Information: Name, email address, username, profile photo, and password. Call Providers may also submit payment information and identity verification details.\n\nUsage Data: App activity (call durations, contact interactions, credit usage), IP address, device type, operating system, and app version.\n\nPayment Information: We do not store full credit card or bank account details. Payments and payouts are securely handled by third-party processors such as Stripe or Braintree.\n\nCommunications: Any messages or call logs made within the app may be stored for customer service, dispute resolution, and compliance."
                            )
                            
                            privacySection(
                                title: "2. How We Use Your Information",
                                content: "• To provide and improve the Service\n• To manage your account and preferences\n• To facilitate secure payments and withdrawals\n• To personalize your experience and offer relevant content\n• To communicate with you (transactional, promotional, and support-related)\n• To prevent fraud and enforce our Terms of Service"
                            )
                            
                            privacySection(
                                title: "3. Sharing of Information",
                                content: "We do not sell your personal data. However, we may share your information with:\n\n• Payment Processors (e.g., Stripe, Braintree) for financial transactions\n• Service Providers assisting with hosting, analytics, customer support, or security\n• Legal Authorities if required by law or to protect our rights or users\n• Other Users as part of using the app (e.g., profile display, username, and call rate if you're a provider)"
                            )
                            
                            privacySection(
                                title: "4. Data Retention",
                                content: "We retain your information for as long as your account is active or as needed to:\n\n• Provide services\n• Comply with legal obligations\n• Resolve disputes\n• Enforce agreements\n\nYou may delete your account at any time, and we will delete your data unless retention is required by law."
                            )
                            
                            privacySection(
                                title: "5. Cookies and Tracking",
                                content: "We use cookies and similar technologies on viddycall.com to:\n\n• Analyze traffic and usage\n• Improve functionality\n• Remember user preferences\n\nYou can manage cookie settings through your browser."
                            )
                            
                            privacySection(
                                title: "6. Your Privacy Rights",
                                content: "Depending on your location, you may have rights including:\n\n• Accessing or correcting your data\n• Deleting your account and personal information\n• Objecting to or restricting data processing\n\nTo exercise your rights, email us at privacy@viddycall.com."
                            )
                            
                            privacySection(
                                title: "7. Security",
                                content: "We use industry-standard encryption and security practices to protect your data. However, no method of transmission over the internet or method of electronic storage is 100% secure."
                            )
                            
                            privacySection(
                                title: "8. Children's Privacy",
                                content: "ViddyCall is not intended for use by anyone under the age of 18. We do not knowingly collect personal information from children."
                            )
                            
                            privacySection(
                                title: "9. International Users",
                                content: "If you access ViddyCall from outside the United States, you agree that your data may be transferred to and processed in the U.S. or other countries where we operate."
                            )
                            
                            privacySection(
                                title: "10. Changes to This Policy",
                                content: "We may update this Privacy Policy from time to time. If we make material changes, we will notify you through the app or website. Continued use of the Service means you accept the changes."
                            )
                            
                            privacySection(
                                title: "11. Contact Us",
                                content: "For any questions or concerns, please contact:\n\nEmail: privacy@viddycall.com\nWebsite: www.viddycall.com"
                            )
                        }
                        .padding(.horizontal)
                        
                        Text("Last updated: 2025")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 20)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(appBlue)
                    }
                }
            }
        }
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(appBlue)
            
            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    PrivacyPolicyView()
} 