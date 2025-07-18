//
//  AppViewModel.swift
//  VidCallApp
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AppViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var showingRateEditSheet: Bool = false

    private var listenerHandle: AuthStateDidChangeListenerHandle?

    init() {
        listenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            if let user = user {
                print("✅ User logged in: \(user.uid)")
                self?.isLoggedIn = true
                self?.fetchUserProfile(for: user.uid)
            } else {
                print("🔴 No user logged in")
                self?.isLoggedIn = false
                self?.userProfile = nil
            }
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, username: String, userType: UserType) {
        let cleanedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        isLoading = true

        // First, check username availability
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("username", isEqualTo: cleanedUsername)
            .limit(to: 1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    print("❌ Error checking username: \(error.localizedDescription)")
                    self.alertMessage = "Unable to check username availability. Please try again."
                    self.showingAlert = true
                    return
                }
                
                // Check if username already exists
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    self.isLoading = false
                    print("❌ Username '\(cleanedUsername)' is already taken")
                    self.alertMessage = "Username '\(cleanedUsername)' is already taken. Please choose a different username."
                    self.showingAlert = true
                    return
                }
                
                // Username is available, proceed with Firebase Auth
                Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                    guard let self = self else { return }

                    if let error = error {
                        self.isLoading = false
                        print("❌ Firebase Auth error: \(error.localizedDescription)")
                        self.alertMessage = "Sign-up error: \(error.localizedDescription)"
                        self.showingAlert = true
                        return
                    }

                    guard let user = result?.user else {
                        self.isLoading = false
                        self.alertMessage = "Unexpected error: user creation failed."
                        self.showingAlert = true
                        return
                    }

                    print("✅ Firebase Auth created user: \(user.uid)")
                    
                    // Now save the user profile with the verified username
                    db.collection("users").document(user.uid).setData([
                        "email": email,
                        "username": cleanedUsername,
                        "contacts": [],
                        "credits": 0.0,
                        "ratePerMinute": 5.0, // Default $5 per minute
                        "userType": userType.rawValue,
                        "isAvailable": true, // Default to available
                        "blockedUsers": [], // Initialize empty blocked users list
                        "paypalEmail": "" // Default to empty string
                    ]) { error in
                        self.isLoading = false

                        if let error = error {
                            print("❌ Firestore write failed: \(error.localizedDescription)")
                            self.alertMessage = "Failed to save user profile: \(error.localizedDescription)"
                            self.showingAlert = true
                        } else {
                            print("✅ Firestore user profile saved successfully.")
                            self.fetchUserProfile(for: user.uid)
                        }
                    }
                }
            }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) {
        isLoading = true

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            self.isLoading = false

            if let error = error {
                self.alertMessage = "Sign-in error: \(error.localizedDescription)"
                self.showingAlert = true
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("👋 Signed out")
        } catch {
            self.alertMessage = "Sign-out error: \(error.localizedDescription)"
            self.showingAlert = true
        }
    }

    // Alias for compatibility with `HomeView.swift`
    func logOut() {
        signOut()
    }

    // MARK: - Fetch User Profile
    func fetchUserProfile(for uid: String) {
        isLoading = true
        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            self.isLoading = false

            if let error = error {
                self.alertMessage = "Failed to load profile: \(error.localizedDescription)"
                self.showingAlert = true
                return
            }

            guard let data = snapshot?.data(),
                  let email = data["email"] as? String,
                  let username = data["username"] as? String else {
                self.alertMessage = "Incomplete user profile data."
                self.showingAlert = true
                return
            }

            let contacts = data["contacts"] as? [String] ?? []
            
            // Handle both Int and Double credit formats for backward compatibility
            let credits: Double
            if let creditsInt = data["credits"] as? Int {
                credits = Double(creditsInt)
            } else if let creditsDouble = data["credits"] as? Double {
                credits = creditsDouble
            } else {
                credits = 0.0
            }
            
            let ratePerMinute = data["ratePerMinute"] as? Double ?? 5.0 // Default $5 per minute
            let userTypeString = data["userType"] as? String ?? "customer"
            let userType = UserType(rawValue: userTypeString) ?? .customer
            let isAvailable = data["isAvailable"] as? Bool ?? true // Default to available
            let sessionRate = data["sessionRate"] as? Double
            let billingModeRaw = data["billingMode"] as? String
            let billingMode = BillingMode(rawValue: billingModeRaw ?? "") ?? .perMinute
            let blockedUsers = data["blockedUsers"] as? [String] ?? []
            let paypalEmail = data["paypalEmail"] as? String

            DispatchQueue.main.async {
                self.userProfile = UserProfile(
                    uid: uid,
                    email: email,
                    username: username,
                    contacts: contacts,
                    credits: credits,
                    ratePerMinute: ratePerMinute,
                    sessionRate: sessionRate,
                    billingMode: billingMode,
                    userType: userType,
                    isAvailable: isAvailable,
                    blockedUsers: blockedUsers,
                    paypalEmail: paypalEmail
                )
                print("✅ Profile loaded: \(username), credits: \(credits), rate: $\(ratePerMinute)/min, session: $\(sessionRate ?? 0), mode: \(billingMode.rawValue), type: \(userType.rawValue), available: \(isAvailable), blocked: \(blockedUsers.count) users")
            }
        }
    }

    // MARK: - Username Availability Result
    struct UsernameAvailabilityResult {
        let isAvailable: Bool
        let checkSucceeded: Bool
        let errorMessage: String?
    }

    // MARK: - Check Username Availability
    func isUsernameAvailable(_ username: String, completion: @escaping (UsernameAvailabilityResult) -> Void) {
        let db = Firestore.firestore()
        let cleaned = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("🔍 Checking username availability for: '\(cleaned)'")

        // Try to get the user document directly by username
        db.collection("users")
            .whereField("username", isEqualTo: cleaned)
            .limit(to: 1) // Only need to check if any document exists
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error checking username: \(error.localizedDescription)")
                    print("❌ Error code: \(error)")
                    
                    // If there's a permission error, we can't determine availability
                    completion(UsernameAvailabilityResult(
                        isAvailable: false,
                        checkSucceeded: false,
                        errorMessage: error.localizedDescription
                    ))
                    return
                }

                let isAvailable = snapshot?.documents.isEmpty ?? true
                print("✅ Username check complete: \(cleaned) is \(isAvailable ? "available" : "taken")")
                completion(UsernameAvailabilityResult(
                    isAvailable: isAvailable,
                    checkSucceeded: true,
                    errorMessage: nil
                ))
            }
    }

    // MARK: - Delete Account and All Related Data
    func deleteAccountAndData(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser, let uid = userProfile?.uid else {
            completion(false, "No user logged in.")
            return
        }
        isLoading = true
        let db = Firestore.firestore()
        // 1. Delete all transactions where user is involved
        let txQuery = db.collection("transactions").whereField("userId", isEqualTo: uid)
        txQuery.getDocuments { txSnapshot, txError in
            if let txError = txError {
                self.isLoading = false
                completion(false, "Failed to fetch transactions: \(txError.localizedDescription)")
                return
            }
            let batch = db.batch()
            txSnapshot?.documents.forEach { batch.deleteDocument($0.reference) }
            // 2. Delete all transactions where user is relatedUsername (for providers)
            let relatedQuery = db.collection("transactions").whereField("relatedUsername", isEqualTo: self.userProfile?.username ?? "")
            relatedQuery.getDocuments { relSnapshot, relError in
                if let relError = relError {
                    self.isLoading = false
                    completion(false, "Failed to fetch related transactions: \(relError.localizedDescription)")
                    return
                }
                relSnapshot?.documents.forEach { batch.deleteDocument($0.reference) }
                // 3. Delete all callRequests for this user
                db.collection("callRequests").document(uid).delete { _ in }
                // 4. Delete all contacts subcollection
                db.collection("users").document(uid).collection("contacts").getDocuments { contactsSnapshot, _ in
                    contactsSnapshot?.documents.forEach { batch.deleteDocument($0.reference) }
                    // 5. Delete user profile
                    batch.deleteDocument(db.collection("users").document(uid))
                    // Commit batch
                    batch.commit { batchError in
                        if let batchError = batchError {
                            self.isLoading = false
                            completion(false, "Failed to delete user data: \(batchError.localizedDescription)")
                            return
                        }
                        // 6. Delete from Firebase Auth
                        user.delete { authError in
                            self.isLoading = false
                            if let authError = authError {
                                completion(false, "Failed to delete account: \(authError.localizedDescription)")
                            } else {
                                self.userProfile = nil
                                self.isLoggedIn = false
                                completion(true, nil)
                            }
                        }
                    }
                }
            }
        }
    }
}

