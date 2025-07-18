import Foundation
import FirebaseAuth
import FirebaseFirestore

class PayPalPayoutsManager: ObservableObject {
    static let shared = PayPalPayoutsManager()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var payoutHistory: [PayoutRecord] = []
    
    private let serverURL = "https://web-production-29a59.up.railway.app"
    
    private init() {
        print("🔄 PayPalPayoutsManager initialized")
    }
    
    // MARK: - Request Payout
    func requestPayout(amount: Double, paypalEmail: String, completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, "User not authenticated")
            return
        }
        
        print("🔄 Requesting payout for amount: $\(amount) to \(paypalEmail)")
        isLoading = true
        
        guard let url = URL(string: "\(serverURL)/api/paypal/payouts") else {
            isLoading = false
            completion(false, "Invalid server URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "userId": user.uid,
            "amount": amount,
            "paypalEmail": paypalEmail,
            "currency": "USD"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            isLoading = false
            completion(false, "Failed to create payout request")
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    completion(false, "No response from server")
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let success = json?["success"] as? Bool, success {
                        print("✅ Payout requested successfully")
                        
                        // Update user balance in Firestore
                        self?.updateUserBalanceAfterPayout(amount: amount) { balanceUpdated in
                            if balanceUpdated {
                                // Save payout record
                                self?.savePayoutRecord(amount: amount, paypalEmail: paypalEmail, payoutId: json?["payoutId"] as? String ?? "") { recordSaved in
                                    completion(true, nil)
                                }
                            } else {
                                completion(false, "Payout requested but failed to update balance")
                            }
                        }
                    } else {
                        let errorMessage = json?["error"] as? String ?? "Payout request failed"
                        print("❌ Payout failed: \(errorMessage)")
                        completion(false, errorMessage)
                    }
                } catch {
                    print("❌ JSON parsing error: \(error)")
                    completion(false, "Failed to parse server response")
                }
            }
        }.resume()
    }
    
    // MARK: - Update User Balance After Payout
    private func updateUserBalanceAfterPayout(amount: Double, completion: @escaping (Bool) -> Void) {
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
            
            guard let currentBalance = userDocument.data()?["balance"] as? Double else {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Unable to retrieve balance from user document"
                ])
                errorPointer?.pointee = error
                return nil
            }
            
            let newBalance = currentBalance - amount
            if newBalance < 0 {
                let error = NSError(domain: "AppErrorDomain", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Insufficient balance for payout"
                ])
                errorPointer?.pointee = error
                return nil
            }
            
            transaction.updateData(["balance": newBalance], forDocument: userRef)
            print("✅ Balance updated after payout: \(currentBalance) -> \(newBalance)")
            return nil
        } completion: { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error updating balance: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ Balance updated successfully")
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Save Payout Record
    private func savePayoutRecord(amount: Double, paypalEmail: String, payoutId: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        
        let payoutData: [String: Any] = [
            "userId": user.uid,
            "amount": amount,
            "paypalEmail": paypalEmail,
            "payoutId": payoutId,
            "status": "pending",
            "timestamp": FieldValue.serverTimestamp(),
            "type": "provider_payout"
        ]
        
        let payoutRef = db.collection("payouts").document()
        
        payoutRef.setData(payoutData) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error saving payout record: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ Payout record saved successfully")
                    completion(true)
                }
            }
        }
    }
    
    // MARK: - Get Payout History
    func getPayoutHistory(completion: @escaping ([PayoutRecord]?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(nil)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("payouts")
            .whereField("userId", isEqualTo: user.uid)
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching payouts: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                let payouts = snapshot?.documents.compactMap { document -> PayoutRecord? in
                    let data = document.data()
                    return PayoutRecord(
                        id: document.documentID,
                        amount: data["amount"] as? Double ?? 0.0,
                        paypalEmail: data["paypalEmail"] as? String ?? "",
                        payoutId: data["payoutId"] as? String ?? "",
                        status: data["status"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        type: data["type"] as? String ?? ""
                    )
                }
                
                DispatchQueue.main.async {
                    self.payoutHistory = payouts ?? []
                }
                
                completion(payouts)
            }
    }
    
    // MARK: - Check Payout Status
    func checkPayoutStatus(payoutId: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/paypal/payouts/\(payoutId)/status") else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error checking payout status: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    completion(nil)
                    return
                }
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let status = json?["status"] as? String {
                        completion(status)
                    } else {
                        completion(nil)
                    }
                } catch {
                    print("❌ Error parsing payout status: \(error)")
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // MARK: - Get Available Balance for Payout
    func getAvailableBalanceForPayout(completion: @escaping (Double) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(0.0)
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { document, error in
            if let error = error {
                print("❌ Error fetching user balance: \(error.localizedDescription)")
                completion(0.0)
                return
            }
            
            let balance = document?.data()?["balance"] as? Double ?? 0.0
            completion(balance)
        }
    }
}

// MARK: - Payout Record Model
struct PayoutRecord: Identifiable {
    let id: String
    let amount: Double
    let paypalEmail: String
    let payoutId: String
    let status: String
    let timestamp: Date
    let type: String
    
    var statusColor: String {
        switch status.lowercased() {
        case "completed":
            return "green"
        case "pending":
            return "orange"
        case "failed":
            return "red"
        default:
            return "gray"
        }
    }
    
    var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
} 