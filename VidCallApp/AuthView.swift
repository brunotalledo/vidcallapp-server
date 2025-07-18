//
//  AuthView.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/28/25.
//
import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoggedIn: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    @State private var errorMessage: String?
    @State private var showingAlert: Bool = false
    
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [appBlue.opacity(0.3), Color.black]),
                startPoint: .top,
                endPoint: .center
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Logo and Title
                VStack(spacing: 16) {
                    Circle()
                        .fill(.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .fill(appBlue)
                                .padding(8)
                                .overlay(
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                )
                        )
                        .shadow(color: appBlue.opacity(0.5), radius: 16)
                    
                    Text("VIDDYCALL")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 60)
                
                // Login/Signup Form
                VStack(spacing: 20) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        TextField("", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        HStack {
                            if isPasswordVisible {
                                TextField("", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                            }
                            
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    // Confirm Password Field (only for signup)
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            HStack {
                                if isConfirmPasswordVisible {
                                    TextField("", text: $confirmPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("", text: $confirmPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .textInputAutocapitalization(.never)
                                }
                                
                                Button(action: {
                                    isConfirmPasswordVisible.toggle()
                                }) {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    // Login/Signup Button
                    Button(action: {
                        if isSignUp {
                            // Validate signup
                            if password != confirmPassword {
                                errorMessage = "Passwords do not match"
                                showingAlert = true
                                return
                            }
                            if password.count < 6 {
                                errorMessage = "Password must be at least 6 characters"
                                showingAlert = true
                                return
                            }
                            signUp()
                        } else {
                            logIn()
                        }
                    }) {
                        Text(isSignUp ? "Sign Up" : "Log In")
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
                    
                    // Switch between Login/Signup
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                            // Clear fields when switching
                            if isSignUp {
                                password = ""
                                confirmPassword = ""
                            } else {
                                password = ""
                                confirmPassword = ""
                            }
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up")
                            .font(.system(size: 14))
                            .foregroundColor(appBlue)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $isLoggedIn) {
            HomeView()
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }

    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "Sign Up Error: \(error.localizedDescription)"
                self.showingAlert = true
            } else {
                self.isLoggedIn = true
            }
        }
    }

    private func logIn() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = "Login Error: \(error.localizedDescription)"
                self.showingAlert = true
            } else {
                self.isLoggedIn = true
            }
        }
    }
}

struct LoggedInView: View {
    var body: some View {
        VStack {
            Text("You are logged in!")
                .font(.largeTitle)
                .padding()
        }
    }
}
