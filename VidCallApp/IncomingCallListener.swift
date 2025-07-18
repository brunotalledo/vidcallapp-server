//
//  IncomingCallListener.swift
//  VidCallApp
//

import Foundation
import FirebaseFirestore

class IncomingCallListener {
    static let shared = IncomingCallListener()
    private var listener: ListenerRegistration?

    func startListening(for uid: String, onCallReceived: @escaping (IncomingCall?) -> Void) {
        stopListening()
        print("[IncomingCallListener] Setting up Firestore listener for userID: \(uid)")
        let db = Firestore.firestore()
        listener = db.collection("callRequests").document(uid).addSnapshotListener { snapshot, error in
            print("[IncomingCallListener] Snapshot received: \(snapshot?.data() ?? [:])")
            if let error = error {
                print("❌ Listener error: \(error.localizedDescription)")
                onCallReceived(nil)
                return
            }

            guard let data = snapshot?.data() else {
                print("⚠️ No data in call request document. Call likely ended (document deleted).")
                print("📄 Document exists: \(snapshot?.exists ?? false)")
                print("📄 Document ID: \(snapshot?.documentID ?? "unknown")")
                onCallReceived(nil)
                return
            }

            print("📦 Listener triggered with data: \(data)")
            print("📦 Document exists: \(snapshot?.exists ?? false)")

            guard let callerID = data["callerID"] as? String,
                  let callerName = data["callerName"] as? String,
                  let roomID = data["roomID"] as? String else {
                print("❌ Incomplete call data. Available fields: \(data.keys)")
                onCallReceived(nil)
                return
            }

            // Check if the user is available for calls
            db.collection("users").document(uid).getDocument { userSnapshot, userError in
                if let userError = userError {
                    print("❌ Error checking user availability: \(userError.localizedDescription)")
                    onCallReceived(nil)
                    return
                }
                
                let userData = userSnapshot?.data() ?? [:]
                let isAvailable = userData["isAvailable"] as? Bool ?? true
                let userType = userData["userType"] as? String ?? "customer"
                
                // Only check availability for providers
                if userType == "provider" && !isAvailable {
                    print("❌ Provider \(uid) is not available for calls. Rejecting call from \(callerName)")
                    // Delete the call request since the provider is unavailable
                    db.collection("callRequests").document(uid).delete { deleteError in
                        if let deleteError = deleteError {
                            print("⚠️ Failed to delete call request for unavailable provider: \(deleteError.localizedDescription)")
                        } else {
                            print("✅ Call request deleted for unavailable provider")
                        }
                    }
                    onCallReceived(nil)
                    return
                }
                
                print("✅ User \(uid) is available for calls")
                print("✅ Creating IncomingCall object with:")
                print("   - Caller ID: \(callerID)")
                print("   - Caller Name: \(callerName)")
                print("   - Room ID: \(roomID)")
                
                let call = IncomingCall(callerID: callerID, callerName: callerName, roomID: roomID)
                onCallReceived(call)
            }
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
