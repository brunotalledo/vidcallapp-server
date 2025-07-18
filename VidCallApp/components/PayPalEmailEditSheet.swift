import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PayPalEmailEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    var onSave: (String) -> Void

    init(currentEmail: String?, onSave: @escaping (String) -> Void) {
        _email = State(initialValue: currentEmail ?? "")
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("PayPal Account")
                    .font(.title2.bold())
                    .padding(.top)
                Text("Enter the PayPal email where you want to receive withdrawals.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                TextField("PayPal Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal)
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.body)
                }
                Spacer()
                Button(action: saveEmail) {
                    if isSaving {
                        ProgressView()
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Save PayPal Email")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(isSaving || !isValidEmail(email))
                .padding(.horizontal)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.blue)
                    }
                }
            }
        }
    }

    private func saveEmail() {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User not authenticated."
            return
        }
        isSaving = true
        errorMessage = nil
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).updateData([
            "paypalEmail": email
        ]) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Failed to save email: \(error.localizedDescription)"
            } else {
                onSave(email)
                dismiss()
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
} 