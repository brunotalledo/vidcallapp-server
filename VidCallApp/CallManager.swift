//
//  CallManager.swift
//  VidCallApp
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class CallManager: ObservableObject {
    static let shared = CallManager()

    @Published var incomingCall: IncomingCall?

    func sendCall(to recipientUID: String, from caller: UserContact, roomID: String) {
        let db = Firestore.firestore()
        
        print("📞 CallManager: Starting call request process")
        print("📞 CallManager: Recipient UID: \(recipientUID)")
        print("📞 CallManager: Caller: \(caller.name) (\(caller.id))")
        print("📞 CallManager: Room ID: \(roomID)")

        // Check if recipient has blocked the caller
        db.collection("users").document(recipientUID).getDocument { snapshot, error in
            if let error = error {
                print("❌ Error checking block status: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(),
               let blockedUsers = data["blockedUsers"] as? [String],
               blockedUsers.contains(caller.id) {
                print("❌ Call blocked: \(caller.name) is blocked by recipient \(recipientUID)")
                // The call is blocked - caller won't know, but call won't go through
                return
            }
            
            // Proceed with normal call logic
            // First, clean up any existing call requests
            db.collection("callRequests").document(recipientUID).delete { error in
                if let error = error {
                    print("⚠️ Failed to clean up old call request: \(error.localizedDescription)")
                } else {
                    print("🧹 Old call request cleaned up successfully")
                }
                
                // Then send the new call request
                let callData: [String: Any] = [
                    "callerID": caller.id,
                    "callerName": caller.name,
                    "roomID": roomID,
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                print("📞 CallManager: Creating Firestore document with data: \(callData)")
                
                db.collection("callRequests").document(recipientUID).setData(callData) { error in
                    if let error = error {
                        print("❌ Failed to send call request: \(error.localizedDescription)")
                    } else {
                        print("✅ Call request sent to UID: \(recipientUID)")
                        print("✅ Firestore document created successfully")
                    }
                }
            }
        }
    }

    func clearCall() {
        print("🧹 CallManager.clearCall() called")
        // Clean up the call request when clearing
        let db = Firestore.firestore()
        if let myUID = Auth.auth().currentUser?.uid {
            print("🧹 Deleting call request document for UID: \(myUID)")
            db.collection("callRequests").document(myUID).delete { error in
                if let error = error {
                    print("⚠️ Failed to clean up call request: \(error.localizedDescription)")
                } else {
                    print("✅ Call request document deleted successfully")
                }
            }
        } else {
            print("⚠️ No current user UID available for call cleanup")
        }
        incomingCall = nil
        print("✅ CallManager.clearCall() completed")
    }
}
