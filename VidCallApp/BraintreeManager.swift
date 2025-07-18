import Foundation
import BraintreeDropIn
import FirebaseAuth
import FirebaseFirestore

class BraintreeManager: ObservableObject {
    static let shared = BraintreeManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var savedPaymentMethods: [PaymentMethod] = []
    
    private let serverURL = "https://web-production-29a59.up.railway.app" // Updated to Railway server URL
    
    private init() {
        print("🔄 BraintreeManager initialized")
    }
    
    // MARK: - Get Client Token with Customer ID
    private func getClientToken(for customerId: String, completion: @escaping (String?, Error?) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/braintree/client-token?customerId=\(customerId)") else {
            completion(nil, NSError(domain: "Invalid URL", code: -1, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let data = data else {
                    completion(nil, NSError(domain: "No data", code: -1, userInfo: nil))
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let clientToken = json?["clientToken"] as? String {
                        completion(clientToken, nil)
                    } else {
                        completion(nil, NSError(domain: "Invalid response", code: -1, userInfo: nil))
                    }
                } catch {
                    completion(nil, error)
                }
            }
        }.resume()
    }
    
    // MARK: - Show Drop-in Payment UI with Customer Support
    func showDropIn(amount: String, from viewController: UIViewController, completion: @escaping (Bool, String?) -> Void) {
        print("🔄 Starting Drop-in payment flow for amount: \(amount)")
        isLoading = true
        
        guard let userID = Auth.auth().currentUser?.uid else {
            isLoading = false
            completion(false, "User not authenticated")
            return
        }
        
        getClientToken(for: userID) { [weak self] clientToken, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to get client token: \(error.localizedDescription)")
                self.isLoading = false
                completion(false, "Failed to initialize payment")
                return
            }
            
            guard let clientToken = clientToken else {
                self.isLoading = false
                completion(false, "No client token received")
                return
            }
            
            let request = BTDropInRequest()
            request.vaultManager = true // Enable vault management
            
            let dropIn = BTDropInController(authorization: clientToken, request: request) { [weak self] (controller, result, error) in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("❌ Drop-in error: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        self?.showError = true
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    if result?.isCanceled == true {
                        print("🚫 Drop-in cancelled")
                        completion(false, "Payment cancelled")
                        return
                    }
                    
                    if let paymentMethod = result?.paymentMethod {
                        print("✅ Payment method selected: \(paymentMethod.nonce)")
                        // Process the payment with the server
                        self?.processPaymentWithServer(paymentMethodNonce: paymentMethod.nonce, amount: amount) { success, error in
                            completion(success, error)
                        }
                    } else {
                        print("❌ No payment method selected")
                        completion(false, "No payment method selected")
                    }
                }
                controller.dismiss(animated: true, completion: nil)
            }
            
            if let dropIn = dropIn {
                print("✅ Presenting Drop-in")
                viewController.present(dropIn, animated: true, completion: nil)
            } else {
                print("❌ Failed to create Drop-in controller")
                self.isLoading = false
                completion(false, "Failed to create payment interface")
            }
        }
    }
    
    // MARK: - Process Payment with Server
    private func processPaymentWithServer(paymentMethodNonce: String, amount: String, completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "User not authenticated")
            return
        }
        
        print("🔄 Processing payment with server...")
        
        let url = URL(string: "\(serverURL)/api/braintree/transactions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "paymentMethodNonce": paymentMethodNonce,
            "amount": amount,
            "userId": user.uid
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Error creating request body: \(error)")
            completion(false, "Failed to create payment request")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received")
                    completion(false, "No response from server")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = json["success"] as? Bool, success {
                            print("✅ Payment processed successfully")
                            // Update user credits in Firestore
                            self?.updateUserCredits(amount: Double(amount) ?? 0.0) { creditsUpdated in
                                if creditsUpdated {
                                    completion(true, nil)
                                } else {
                                    completion(false, "Payment successful but failed to update credits")
                                }
                            }
                        } else {
                            let errorMessage = json["error"] as? String ?? "Payment failed"
                            print("❌ Payment failed: \(errorMessage)")
                            completion(false, errorMessage)
                        }
                    } else {
                        print("❌ Invalid JSON response")
                        completion(false, "Invalid server response")
                    }
                } catch {
                    print("❌ JSON parsing error: \(error)")
                    completion(false, "Failed to parse server response")
                }
            }
        }.resume()
    }
    
    // MARK: - Update User Credits in Firestore
    private func updateUserCredits(amount: Double, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        db.runTransaction { transaction, errorPointer in
            let userDocument: DocumentSnapshot
            do {
                userDocument = try transaction.getDocument(userRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let oldCredits = userDocument.data()?["credits"] as? Double else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve credits from user document"
                ])
                errorPointer?.pointee = error
                return nil
            }
            
            let newCredits = oldCredits + amount
            transaction.updateData(["credits": newCredits], forDocument: userRef)
            
            // Get username for transaction record
            let username = userDocument.data()?["username"] as? String ?? "Unknown"
            
            // Also save transaction record
            let transactionData: [String: Any] = [
                "userId": user.uid,
                "amount": amount,
                "paymentType": "credit_purchase",
                "status": "completed",
                "timestamp": FieldValue.serverTimestamp(),
                "username": username
            ]
            
            let transactionRef = db.collection("transactions").document()
            transaction.setData(transactionData, forDocument: transactionRef)
            
            print("✅ Credits updated: \(oldCredits) -> \(newCredits)")
            return nil
        } completion: { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error updating credits: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ Credits updated successfully")
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Show Drop-in for Payment Method Setup with Customer Support
    func showDropInForSetup(from viewController: UIViewController, completion: @escaping (Bool, String?) -> Void) {
        print("🔄 Starting Drop-in setup flow")
        isLoading = true
        
        guard let userID = Auth.auth().currentUser?.uid else {
            isLoading = false
            completion(false, "User not authenticated")
            return
        }
        
        getClientToken(for: userID) { [weak self] clientToken, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to get client token: \(error.localizedDescription)")
                self.isLoading = false
                completion(false, "Failed to initialize payment setup")
                return
            }
            
            guard let clientToken = clientToken else {
                self.isLoading = false
                completion(false, "No client token received")
                return
            }
            
            let request = BTDropInRequest()
            request.vaultManager = true // Enable vault management
            
            let dropIn = BTDropInController(authorization: clientToken, request: request) { [weak self] (controller, result, error) in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        print("❌ Drop-in setup error: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        self?.showError = true
                        completion(false, error.localizedDescription)
                        return
                    }
                    
                    if result?.isCanceled == true {
                        print("🚫 Drop-in setup cancelled")
                        completion(false, "Setup cancelled")
                        return
                    }
                    
                    if let paymentMethod = result?.paymentMethod {
                        print("✅ Payment method setup successful: \(paymentMethod.nonce)")
                        // Save to vault via server
                        self?.savePaymentMethodToVault(paymentMethodNonce: paymentMethod.nonce, customerId: userID) { success in
                            completion(success, success ? nil : "Failed to save payment method")
                        }
                    } else {
                        print("❌ No payment method selected for setup")
                        completion(false, "No payment method selected")
                    }
                }
                controller.dismiss(animated: true, completion: nil)
            }
            
            if let dropIn = dropIn {
                print("✅ Presenting Drop-in for setup")
                viewController.present(dropIn, animated: true, completion: nil)
            } else {
                print("❌ Failed to create Drop-in controller for setup")
                isLoading = false
                completion(false, "Failed to create payment interface")
            }
        }
    }
    
    // MARK: - Save Payment Method to Vault
    private func savePaymentMethodToVault(paymentMethodNonce: String, customerId: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/braintree/payment-methods") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "paymentMethodNonce": paymentMethodNonce,
            "customerId": customerId
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error saving payment method: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let data = data else {
                    completion(false)
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let success = json?["success"] as? Bool, success {
                        print("✅ Payment method saved to vault")
                        completion(true)
                    } else {
                        print("❌ Failed to save payment method")
                        completion(false)
                    }
                } catch {
                    print("❌ Error parsing response: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch Saved Payment Methods
    func fetchSavedPaymentMethods(completion: @escaping ([PaymentMethod]) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ No user ID available for fetching payment methods")
            completion([])
            return
        }
        
        print("🔍 Fetching payment methods for user: \(userID)")
        
        guard let url = URL(string: "\(serverURL)/api/braintree/payment-methods/\(userID)") else {
            print("❌ Invalid URL for fetching payment methods")
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("🌐 Making request to: \(url)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching payment methods: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP Response: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("❌ No data received from server")
                    completion([])
                    return
                }
                
                print("📦 Received data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let paymentMethodsData = json?["paymentMethods"] as? [[String: Any]] {
                        print("✅ Found \(paymentMethodsData.count) payment methods")
                        let paymentMethods = paymentMethodsData.compactMap { PaymentMethod(from: $0) }
                        self.savedPaymentMethods = paymentMethods
                        completion(paymentMethods)
                    } else {
                        print("⚠️ No payment methods found in response")
                        completion([])
                    }
                } catch {
                    print("❌ Error parsing payment methods: \(error.localizedDescription)")
                    completion([])
                }
            }
        }.resume()
    }
    
    // MARK: - Delete Payment Method
    func deletePaymentMethod(token: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/braintree/payment-methods/\(token)") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error deleting payment method: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let data = data else {
                    completion(false)
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let success = json?["success"] as? Bool, success {
                        print("✅ Payment method deleted")
                        completion(true)
                    } else {
                        print("❌ Failed to delete payment method")
                        completion(false)
                    }
                } catch {
                    print("❌ Error parsing delete response: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }.resume()
    }
    
    // MARK: - Get Transaction History
    func getTransactionHistory(completion: @escaping ([TransactionRecord]?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(nil)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("transactions")
            .whereField("userId", isEqualTo: user.uid)
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching transactions: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                let transactions = snapshot?.documents.compactMap { document -> TransactionRecord? in
                    let data = document.data()
                    return TransactionRecord(
                        id: document.documentID,
                        amount: data["amount"] as? Double ?? 0.0,
                        paymentType: data["paymentType"] as? String ?? "",
                        status: data["status"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        username: data["username"] as? String ?? "",
                        relatedUsername: data["relatedUsername"] as? String ?? "",
                        callDuration: data["callDuration"] as? Int ?? 0,
                        callRate: data["callRate"] as? Double
                    )
                }
                
                completion(transactions)
            }
    }
}

// MARK: - Transaction Record Model
struct TransactionRecord: Identifiable {
    let id: String
    let amount: Double
    let paymentType: String
    let status: String
    let timestamp: Date
    let username: String
    let relatedUsername: String
    let callDuration: Int?
    let callRate: Double?
} 