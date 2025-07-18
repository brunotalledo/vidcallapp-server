//
//  CallDurationManager.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 6/26/25.
//

import Foundation
import FirebaseFirestore
import Combine

class CallDurationManager: ObservableObject {
    static let shared = CallDurationManager()
    
    @Published var currentCallDuration: TimeInterval = 0
    @Published var currentCallCost: Double = 0
    @Published var isCallActive = false
    
    private var callStartTime: Date?
    private var timer: Timer?
    var callData: CallData?
    
    struct CallData {
        let customerUID: String
        let providerUID: String
        let providerRatePerMinute: Double
        let sessionRate: Double?
        let billingMode: BillingMode
        let customerCredits: Double
        let roomID: String
    }
    
    private init() {
        print("🔄 CallDurationManager initialized")
    }
    
    // MARK: - Computed Properties
    var remainingTime: TimeInterval {
        guard let callData = callData else { return 0 }
        let availableMinutes = callData.customerCredits / callData.providerRatePerMinute
        let availableSeconds = availableMinutes * 60
        let remainingSeconds = availableSeconds - currentCallDuration
        return max(0, remainingSeconds)
    }
    
    var isLowBalance: Bool {
        return remainingTime < 60 // Less than 1 minute remaining
    }
    
    // MARK: - Helper Methods
    private func getCurrentCustomerCredits() -> Double {
        // This is a simplified version - in a real app you might want to cache this
        // For now, we'll use the last known credits from the user profile
        // You could also pass this as a parameter or fetch it when needed
        return 0 // This will be updated by the caller
    }
    
    // MARK: - Start Call Tracking
    func startCall(callerUID: String, receiverUID: String, callerRate: Double, receiverRate: Double, roomID: String, customerCredits: Double) {
        // Fetch both user profiles to determine roles
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var callerProfile: [String: Any]?
        var receiverProfile: [String: Any]?
        
        group.enter()
        db.collection("users").document(callerUID).getDocument { snapshot, _ in
            callerProfile = snapshot?.data()
            group.leave()
        }
        group.enter()
        db.collection("users").document(receiverUID).getDocument { snapshot, _ in
            receiverProfile = snapshot?.data()
            group.leave()
        }
        group.notify(queue: .main) {
            guard let caller = callerProfile, let receiver = receiverProfile,
                  let callerType = caller["userType"] as? String,
                  let receiverType = receiver["userType"] as? String else {
                print("❌ Could not fetch both user profiles for call start")
                return
            }
            var customerUID = ""
            var providerUID = ""
            var providerRate: Double = 5.0
            var sessionRate: Double? = nil
            var billingMode: BillingMode = .perMinute
            if callerType == "customer" && receiverType == "provider" {
                customerUID = callerUID
                providerUID = receiverUID
                providerRate = receiver["ratePerMinute"] as? Double ?? 5.0
                sessionRate = receiver["sessionRate"] as? Double
                if let billingModeRaw = receiver["billingMode"] as? String, let mode = BillingMode(rawValue: billingModeRaw) {
                    billingMode = mode
                }
            } else if callerType == "provider" && receiverType == "customer" {
                customerUID = receiverUID
                providerUID = callerUID
                providerRate = caller["ratePerMinute"] as? Double ?? 5.0
                sessionRate = caller["sessionRate"] as? Double
                if let billingModeRaw = caller["billingMode"] as? String, let mode = BillingMode(rawValue: billingModeRaw) {
                    billingMode = mode
                }
            } else {
                print("❌ Invalid call: must be between customer and provider")
                return
            }
            self.callData = CallData(
                customerUID: customerUID,
                providerUID: providerUID,
                providerRatePerMinute: providerRate,
                sessionRate: sessionRate,
                billingMode: billingMode,
                customerCredits: customerCredits,
                roomID: roomID
            )
            self.callStartTime = Date()
            self.currentCallDuration = 0
            self.currentCallCost = 0
            self.isCallActive = true
            print("📞 Call started - Customer: \(customerUID), Provider: \(providerUID)")
            print("💰 Provider rate: $\(providerRate)/min, Session rate: $\(sessionRate ?? 0), Billing mode: \(billingMode.rawValue)")
            print("⏰ Customer credits: $\(customerCredits), Available time: \(customerCredits/providerRate) minutes")
            // Start timer to update duration and cost every second
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateCallDuration()
            }
        }
    }
    
    // MARK: - Update Call Duration
    private func updateCallDuration() {
        guard let startTime = callStartTime, let callData = callData else { return }
        let duration = Date().timeIntervalSince(startTime)
        currentCallDuration = duration
        // Calculate cost based on billing mode
        switch callData.billingMode {
        case .perMinute:
            let minutes = duration / 60.0
            currentCallCost = round(minutes * callData.providerRatePerMinute * 100) / 100
        case .perSession:
            currentCallCost = callData.sessionRate ?? 0
        }
        // Calculate remaining time (only relevant for per-minute)
        if callData.billingMode == .perMinute {
            let availableMinutes = callData.customerCredits / callData.providerRatePerMinute
            let availableSeconds = availableMinutes * 60
            let remainingSeconds = availableSeconds - duration
            let remainingTime = max(0, remainingSeconds)
            print("⏱️ Call duration: \(Int(duration))s, Cost: $\(String(format: "%.2f", currentCallCost)), Remaining: \(Int(remainingTime))s")
            // Check if low balance
            if remainingTime < 60 && remainingTime > 0 {
                print("⚠️ Low balance warning: \(Int(remainingTime))s remaining")
            } else if remainingTime <= 0 {
                print("❌ No balance remaining - call should end")
            }
        } else {
            print("⏱️ Call duration: \(Int(duration))s, Cost: $\(String(format: "%.2f", currentCallCost)) (flat session)")
        }
    }
    
    // MARK: - End Call and Deduct Credits
    func endCall() {
        guard let callData = callData else {
            print("❌ No active call to end")
            return
        }
        timer?.invalidate()
        timer = nil
        let finalDuration = currentCallDuration
        var finalCost: Double = 0
        switch callData.billingMode {
        case .perMinute:
            finalCost = currentCallCost
        case .perSession:
            finalCost = callData.sessionRate ?? 0
        }
        print("📞 Call ended - Duration: \(Int(finalDuration))s, Final cost: $\(String(format: "%.2f", finalCost))")
        // Deduct credits from customer and add to provider
        deductCreditsFromCustomer(amount: finalCost, callData: callData, callDuration: Int(finalDuration))
        self.callData = nil
        callStartTime = nil
        currentCallDuration = 0
        currentCallCost = 0
        isCallActive = false
    }
    
    // MARK: - Force End Call (for when one side ends)
    func forceEndCall() {
        guard let callData = callData else {
            print("❌ No active call to force end")
            return
        }
        timer?.invalidate()
        timer = nil
        let finalCost = currentCallCost
        let finalDuration = currentCallDuration
        print("📞 Call force ended - Duration: \(Int(finalDuration))s, Final cost: $\(String(format: "%.2f", finalCost))")
        deductCreditsFromCustomer(amount: finalCost, callData: callData, callDuration: Int(finalDuration))
        self.callData = nil
        callStartTime = nil
        currentCallDuration = 0
        currentCallCost = 0
        isCallActive = false
    }
    
    // MARK: - Refresh Customer Credits (for when credits are added during call)
    func refreshCustomerCredits(newCredits: Double) {
        guard var callData = callData else {
            print("❌ No active call to refresh credits")
            return
        }
        
        // Update the call data with new credits
        callData = CallData(
            customerUID: callData.customerUID,
            providerUID: callData.providerUID,
            providerRatePerMinute: callData.providerRatePerMinute,
            sessionRate: callData.sessionRate,
            billingMode: callData.billingMode,
            customerCredits: newCredits,
            roomID: callData.roomID
        )
        
        self.callData = callData
        
        // Recalculate remaining time
        let availableMinutes = newCredits / callData.providerRatePerMinute
        let availableSeconds = availableMinutes * 60
        let remainingSeconds = availableSeconds - currentCallDuration
        let remainingTime = max(0, remainingSeconds)
        
        print("💰 Credits refreshed: $\(newCredits), New remaining time: \(Int(remainingTime))s")
    }
    
    // MARK: - Credit Deduction
    private func deductCreditsFromCustomer(amount: Double, callData: CallData, callDuration: Int) {
        let db = Firestore.firestore()
        print("💰 Processing credit deduction: $\(String(format: "%.2f", amount)) from customer \(callData.customerUID)")
        
        // Use batch operation to update both customer and provider in one transaction
        let batch = db.batch()
        
        // Get customer's current credits
        db.collection("users").document(callData.customerUID).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error getting customer credits: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else {
                print("❌ Customer document not found: \(callData.customerUID)")
                return
            }
            let currentCredits: Double
            if let creditsInt = data["credits"] as? Int {
                currentCredits = Double(creditsInt)
            } else if let creditsDouble = data["credits"] as? Double {
                currentCredits = creditsDouble
            } else {
                print("❌ Could not get customer's current credits from document: \(data)")
                return
            }
            let newCustomerCredits = currentCredits - amount
            if newCustomerCredits < 0 {
                print("❌ Customer doesn't have enough credits. Required: $\(String(format: "%.2f", amount)), Available: $\(String(format: "%.2f", currentCredits))")
                return
            }
            
            // Get provider's current credits
            db.collection("users").document(callData.providerUID).getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error getting provider credits: \(error.localizedDescription)")
                    return
                }
                guard let data = snapshot?.data() else {
                    print("❌ Provider document not found: \(callData.providerUID)")
                    return
                }
                let currentProviderCredits: Double
                if let creditsInt = data["credits"] as? Int {
                    currentProviderCredits = Double(creditsInt)
                } else if let creditsDouble = data["credits"] as? Double {
                    currentProviderCredits = creditsDouble
                } else {
                    print("❌ Could not get provider's current credits")
                    return
                }
                let newProviderCredits = currentProviderCredits + (amount * 0.75) // Provider gets 75%, platform takes 25%
                
                // Add both updates to batch
                let customerRef = db.collection("users").document(callData.customerUID)
                let providerRef = db.collection("users").document(callData.providerUID)
                
                batch.updateData(["credits": newCustomerCredits], forDocument: customerRef)
                batch.updateData(["credits": newProviderCredits], forDocument: providerRef)
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("❌ Error updating credits in batch: \(error.localizedDescription)")
                    } else {
                        print("✅ Customer credits updated: $\(String(format: "%.2f", currentCredits)) -> $\(String(format: "%.2f", newCustomerCredits))")
                        print("✅ Provider credits updated: $\(String(format: "%.2f", currentProviderCredits)) -> $\(String(format: "%.2f", newProviderCredits))")
                        
                        // Create transaction records for both customer and provider
                        self.createTransactionRecords(
                            customerUID: callData.customerUID,
                            providerUID: callData.providerUID,
                            amount: amount,
                            callDuration: callDuration,
                            callData: callData
                        )
                        
                        // Notify that credits have been updated
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("CreditsUpdated"), object: nil)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Check Sufficient Credits
    func checkSufficientCredits(for userUID: String, estimatedMinutes: Int = 10, completion: @escaping (Bool, Double) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userUID).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error checking credits: \(error.localizedDescription)")
                completion(false, 0.0)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(false, 0.0)
                return
            }
            
            // Handle both Int and Double credit formats for backward compatibility
            let credits: Double
            if let creditsInt = data["credits"] as? Int {
                credits = Double(creditsInt)
            } else if let creditsDouble = data["credits"] as? Double {
                credits = creditsDouble
            } else {
                completion(false, 0.0)
                return
            }
            
            // For now, assume receiver rate is $5/min (default)
            let estimatedCost = Double(estimatedMinutes) * 5.0
            let hasSufficient = credits >= estimatedCost
            
            completion(hasSufficient, credits)
        }
    }
    
    // MARK: - Get Available Minutes
    func getAvailableMinutes(for userUID: String, completion: @escaping (Int) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userUID).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error getting user data: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(0)
                return
            }
            
            // Handle both Int and Double credit formats for backward compatibility
            let credits: Double
            if let creditsInt = data["credits"] as? Int {
                credits = Double(creditsInt)
            } else if let creditsDouble = data["credits"] as? Double {
                credits = creditsDouble
            } else {
                completion(0)
                return
            }
            
            guard let ratePerMinute = data["ratePerMinute"] as? Double else {
                completion(0)
                return
            }
            
            let availableMinutes = Int(credits / ratePerMinute)
            completion(availableMinutes)
        }
    }
    
    // MARK: - Format Duration
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Format Remaining Time
    func formatRemainingTime(_ remainingTime: TimeInterval) -> String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Format Cost
    func formatCost(_ cost: Double) -> String {
        return String(format: "$%.2f", cost)
    }
    
    // MARK: - Format Call Info (Duration + Remaining)
    func formatCallInfo(duration: TimeInterval, remainingTime: TimeInterval) -> String {
        let durationStr = formatDuration(duration)
        let remainingStr = formatRemainingTime(remainingTime)
        return "\(durationStr) / \(remainingStr) remaining"
    }
    
    // MARK: - Sync Call End
    func syncCallEnd(roomID: String, required: Bool = false) {
        // Skip sync if not required to save Firestore usage
        guard required else {
            print("📞 Call end sync skipped (not required)")
            return
        }
        
        let db = Firestore.firestore()
        
        // Create a call end notification in Firestore
        db.collection("callEnds").document(roomID).setData([
            "endedAt": FieldValue.serverTimestamp(),
            "roomID": roomID
        ]) { error in
            if let error = error {
                print("❌ Error syncing call end: \(error.localizedDescription)")
            } else {
                print("✅ Call end synced for room: \(roomID)")
            }
        }
    }
    
    // MARK: - Create Transaction Records
    private func createTransactionRecords(customerUID: String, providerUID: String, amount: Double, callDuration: Int, callData: CallData) {
        let db = Firestore.firestore()
        // First, get usernames for both customer and provider
        let customerRef = db.collection("users").document(customerUID)
        let providerRef = db.collection("users").document(providerUID)
        customerRef.getDocument { customerSnapshot, customerError in
            if let customerError = customerError {
                print("❌ Error getting customer username: \(customerError.localizedDescription)")
                return
            }
            let customerUsername = customerSnapshot?.data()? ["username"] as? String ?? "Unknown"
            providerRef.getDocument { providerSnapshot, providerError in
                if let providerError = providerError {
                    print("❌ Error getting provider username: \(providerError.localizedDescription)")
                    return
                }
                let providerUsername = providerSnapshot?.data()? ["username"] as? String ?? "Unknown"
                let roomID = callData.roomID
                // --- Customer transaction ---
                let customerDocID = "\(customerUID)_call_payment_\(roomID)"
                let customerTransaction: [String: Any] = [
                    "userId": customerUID,
                    "amount": -amount,
                    "paymentType": "call_payment",
                    "status": "completed",
                    "timestamp": FieldValue.serverTimestamp(),
                    "description": "Video call payment",
                    "username": customerUsername,
                    "relatedUsername": providerUsername,
                    "callDuration": callDuration,
                    "callRate": callData.providerRatePerMinute,
                    "billingMode": callData.billingMode.rawValue,
                    "sessionRate": callData.sessionRate as Any,
                    "roomID": roomID
                ]
                db.collection("transactions").document(customerDocID).setData(customerTransaction) { error in
                    if let error = error {
                        print("❌ Error creating customer transaction: \(error.localizedDescription)")
                    } else {
                        print("✅ Customer transaction record created/updated (docID: \(customerDocID))")
                    }
                }
                // --- Provider transaction ---
                let providerDocID = "\(providerUID)_call_earnings_\(roomID)"
                let providerTransaction: [String: Any] = [
                    "userId": providerUID,
                    "amount": amount * 0.75, // Provider gets 75%
                    "paymentType": "call_earnings",
                    "status": "completed",
                    "timestamp": FieldValue.serverTimestamp(),
                    "description": "Video call earnings",
                    "username": providerUsername,
                    "relatedUsername": customerUsername,
                    "callDuration": callDuration,
                    "callRate": callData.providerRatePerMinute,
                    "billingMode": callData.billingMode.rawValue,
                    "sessionRate": callData.sessionRate as Any,
                    "roomID": roomID
                ]
                db.collection("transactions").document(providerDocID).setData(providerTransaction) { error in
                    if let error = error {
                        print("❌ Error creating provider transaction: \(error.localizedDescription)")
                    } else {
                        print("✅ Provider transaction record created/updated (docID: \(providerDocID))")
                    }
                }
            }
        }
    }
} 