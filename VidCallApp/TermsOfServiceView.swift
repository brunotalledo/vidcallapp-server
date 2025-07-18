import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("ViddyCall Terms of Service")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        
                        Text("Welcome to ViddyCall! These Terms of Service (\"Terms\") govern your use of the ViddyCall mobile application and services (collectively, the \"Service\"). By using ViddyCall, you agree to be bound by these Terms. If you do not agree, do not use the Service.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            termsSection(
                                title: "1. Eligibility",
                                content: "You must be at least 18 years old to use ViddyCall. By creating an account, you represent and warrant that you are of legal age to form a binding contract and are not barred from using the Service under any applicable law."
                            )
                            
                            termsSection(
                                title: "2. User Accounts",
                                content: "You must create an account to access features such as video calling, adding credit, and managing your profile. You are responsible for maintaining the confidentiality of your login credentials and agree to provide accurate, complete, and updated information at all times."
                            )
                            
                            termsSection(
                                title: "3. Call Providers",
                                content: "Call Providers are users who offer video call services through ViddyCall and set their own rates. As a Call Provider, you agree to comply with all applicable laws, must not engage in prohibited, explicit, or illegal content, and your earnings will be tracked and can be withdrawn per our payout process."
                            )
                            
                            termsSection(
                                title: "4. Payments and Credits",
                                content: "Users can purchase in-app credits to make video calls. Credits are non-refundable except where required by law. Call Providers may request payouts by linking a verified payment method (e.g., bank account). Payout times may vary depending on our payment processor. All payments are processed through secure third-party payment processors."
                            )
                            
                            termsSection(
                                title: "5. Prohibited Conduct",
                                content: "You agree not to use the Service for any unlawful, abusive, or exploitative purpose; impersonate another person or misrepresent your identity; harass, threaten, or abuse other users; or attempt to interfere with the platform's functionality or security. You must not harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate based on gender, sexual orientation, religion, ethnicity, race, age, national origin, or disability."
                            )
                            
                            termsSection(
                                title: "6. Content and Communication",
                                content: "All video and chat communication through the app must comply with community standards and legal guidelines. We reserve the right to suspend or ban accounts that violate these standards. Video calls are not recorded by default, but users may record calls with mutual consent in compliance with applicable laws."
                            )
                            
                            termsSection(
                                title: "7. Service Availability",
                                content: "We strive to maintain service availability but do not guarantee uninterrupted access. The service may be temporarily unavailable due to maintenance, technical issues, or other factors beyond our control."
                            )
                            
                            termsSection(
                                title: "8. Suspension and Termination",
                                content: "We reserve the right to suspend or terminate your account at our sole discretion, with or without notice, if you violate these Terms or engage in behavior that harms the platform or its users."
                            )
                            
                            termsSection(
                                title: "9. Intellectual Property",
                                content: "All content and technology provided by ViddyCall (excluding user-generated content) is owned by or licensed to us. You may not use our name, logos, or branding without permission. The service and its original content, features, and functionality are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws."
                            )
                            
                            termsSection(
                                title: "10. Third-Party Services",
                                content: "We may integrate with third-party services (e.g., Stripe, Braintree) for payments and verification. You agree to their terms when using those services."
                            )
                            
                            termsSection(
                                title: "11. Disclaimer of Warranties",
                                content: "The Service is provided \"as is\" and \"as available.\" We make no warranties about the accuracy or reliability of the Service or that the Service will be uninterrupted or error-free."
                            )
                            
                            termsSection(
                                title: "12. Limitation of Liability",
                                content: "To the fullest extent permitted by law, ViddyCall and its affiliates will not be liable for any indirect, incidental, or consequential damages arising out of your use of the Service. In no event shall ViddyCall, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses."
                            )
                            
                            termsSection(
                                title: "13. Dispute Resolution",
                                content: "Any disputes arising out of these Terms will be resolved through binding arbitration or small claims court. You waive your right to a jury trial or to participate in a class action. These Terms shall be interpreted and governed by the laws of the United States, without regard to its conflict of law provisions."
                            )
                            
                            termsSection(
                                title: "14. Changes to Terms",
                                content: "We may modify these Terms at any time. If we make material changes, we'll provide notice in the app or via email. Continued use of the Service means you accept the new Terms. We reserve the right to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect."
                            )
                            
                            termsSection(
                                title: "15. Contact Information",
                                content: "If you have any questions about these Terms of Service, please contact us at support@viddycall.com or through the app's support features."
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
            .navigationTitle("Terms of Service")
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
    
    private func termsSection(title: String, content: String) -> some View {
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
    TermsOfServiceView()
} 
