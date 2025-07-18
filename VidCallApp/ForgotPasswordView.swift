//
//  Item.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/11/25.
//


import SwiftUI
import FirebaseAuth

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var message = ""
    
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [appBlue.opacity(0.3), Color.black]),
                startPoint: .top,
                endPoint: .center
            )
            .edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .fill(appBlue)
                                .padding(8)
                                .overlay(
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                )
                        )
                        .shadow(color: appBlue.opacity(0.5), radius: 16)

                    Text("Reset Password")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 60)

                VStack(spacing: 20) {
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal)

                    Button(action: {
                        sendPasswordReset()
                    }) {
                        Text("Send Reset Link")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [appBlue, appBlue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    Text(message)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(appBlue)
                .padding(.bottom, 30)
            }
        }
    }

    private func sendPasswordReset() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                message = "❌ Error: \(error.localizedDescription)"
            } else {
                message = "✅ Password reset email sent!\nCheck your inbox."
            }
        }
    }
}
