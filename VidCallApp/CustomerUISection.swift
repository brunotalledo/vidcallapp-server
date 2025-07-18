import SwiftUI

struct CustomerUISection: View {
    @Binding var showingAddCredit: Bool
    let appBlue: Color
    let braintreeManager: BraintreeManager

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    showingAddCredit = true
                }) {
                    HStack {
                        Text("Add Credit")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(appBlue)
                    .cornerRadius(8)
                }

                Button(action: {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootViewController = window.rootViewController {
                        braintreeManager.showDropInForSetup(from: rootViewController) { success, error in
                            // Optionally handle result
                        }
                    }
                }) {
                    HStack {
                        Text("Payment Method")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(appBlue)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
} 