//
//  LoginView.swift
//  VidCallApp
//

import SwiftUI
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var viewModel: AppViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var showingForgotPassword = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var selectedUserType: UserType = .customer
    
    // Username search states
    @State private var userSearchStatus: UserSearchStatus = .none
    @State private var searchTask: DispatchWorkItem? = nil
    enum UserSearchStatus { case none, searching, found, notFound }

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

                VStack(spacing: 20) {
                    if isSignUp {
                        Picker("Account Type", selection: $selectedUserType) {
                            Text("Caller").tag(UserType.customer)
                            Text("Call Provider").tag(UserType.provider)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        .onAppear {
                            // Customize segmented control appearance
                            UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(appBlue)
                            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                        }
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .font(.system(size: 15))
                            .frame(height: 38)
                            .padding(.horizontal)
                            .onChange(of: username) {
                                userSearchStatus = .searching
                                searchTask?.cancel()
                                let task = DispatchWorkItem {
                                    viewModel.isUsernameAvailable(username) { result in
                                        DispatchQueue.main.async {
                                            if username.isEmpty {
                                                userSearchStatus = .none
                                            } else if result.checkSucceeded {
                                                userSearchStatus = result.isAvailable ? .found : .notFound
                                            } else {
                                                userSearchStatus = .notFound // Assume taken if check fails
                                            }
                                        }
                                    }
                                }
                                searchTask = task
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: task)
                            }
                        
                        // Username search status
                        HStack(spacing: 8) {
                            if userSearchStatus == .found {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Username available")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                            } else if userSearchStatus == .notFound && !username.isEmpty {
                                Image(systemName: "xmark.octagon.fill")
                                    .foregroundColor(.red)
                                Text("Username taken")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12))
                            } else if userSearchStatus == .searching && !username.isEmpty {
                                ProgressView().scaleEffect(0.7)
                                Text("Checking...")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12))
                            }
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        TextField("", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        HStack {
                            if isPasswordVisible {
                                TextField("", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            } else {
                                SecureField("", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            }

                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }

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
                                        .autocorrectionDisabled(true)
                                } else {
                                    SecureField("", text: $confirmPassword)
                                        .textFieldStyle(CustomTextFieldStyle())
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
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

                    if !isSignUp {
                        Button(action: {
                            showingForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 14))
                                .foregroundColor(appBlue)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    Button(action: {
                        if isSignUp {
                            if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                viewModel.alertMessage = "Username is required"
                                viewModel.showingAlert = true
                                return
                            }
                            if userSearchStatus == .notFound {
                                viewModel.alertMessage = "Username is already taken"
                                viewModel.showingAlert = true
                                return
                            }
                            if userSearchStatus == .searching {
                                viewModel.alertMessage = "Please wait while we check username availability"
                                viewModel.showingAlert = true
                                return
                            }
                            // Only proceed if username is available
                            if userSearchStatus == .found {
                                viewModel.signUp(email: email, password: password, username: username, userType: selectedUserType)
                            } else {
                                viewModel.alertMessage = "Please enter a username"
                                viewModel.showingAlert = true
                            }
                        } else {
                            viewModel.signIn(email: email, password: password)
                        }
                    }) {
                        Text(isSignUp ? "Sign Up" : "Log In")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(isSignUp && (userSearchStatus == .notFound || userSearchStatus == .searching) ? Color.gray : appBlue)
                            .cornerRadius(8)
                    }
                    .disabled(isSignUp && (userSearchStatus == .notFound || userSearchStatus == .searching))

                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                            password = ""
                            confirmPassword = ""
                            username = ""
                            userSearchStatus = .none
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

            if viewModel.isLoading {
                Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
            }
        }
        .hideKeyboardOnTap() // ✅ Dismiss keyboard on outside tap
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView()
        }
        .alert("Error", isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
    
}

#Preview {
    LoginView()
        .environmentObject(AppViewModel())
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboardOnTap() -> some View {
        self.modifier(DismissKeyboardOnTap())
    }
}

struct DismissKeyboardOnTap: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil, from: nil, for: nil
                        )
                    }
            )
    }
}
#endif
