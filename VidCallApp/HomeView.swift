//
//  HomeView.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/28/25.
//



import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
    @EnvironmentObject var viewModel: AppViewModel

    @State private var credits: Double = 0.0
    @State private var contacts: [String] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading profile...")
                } else {
                    if let user = Auth.auth().currentUser {
                        Text("Welcome, \(user.email ?? "User")!")
                            .font(.title)
                            .padding()

                        Text("Credits: $\(String(format: "%.2f", credits))")
                            .font(.headline)

                        Text("Contacts:")
                            .font(.headline)

                        if contacts.isEmpty {
                            Text("No contacts yet.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(contacts, id: \.self) { contact in
                                Text(contact)
                            }
                        }
                    } else {
                        Text("No user logged in.")
                            .foregroundColor(.red)
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    viewModel.logOut()
                }) {
                    Text("Log Out")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Home")
            .onAppear(perform: loadUserProfile)  // ✅ Load user profile when screen appears
        }
    }

    private func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Unable to find user ID."
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error loading profile: \(error.localizedDescription)"
                    self.isLoading = false
                } else if let data = snapshot?.data() {
                    // Handle both Int and Double credit formats for backward compatibility
                    if let creditsInt = data["credits"] as? Int {
                        self.credits = Double(creditsInt)
                    } else if let creditsDouble = data["credits"] as? Double {
                        self.credits = creditsDouble
                    } else {
                        self.credits = 0.0
                    }
                    self.contacts = data["contacts"] as? [String] ?? []
                    self.isLoading = false
                } else {
                    self.errorMessage = "User profile not found."
                    self.isLoading = false
                }
            }
        }
    }
}
