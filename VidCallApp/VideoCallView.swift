//
//  VideoCallView.swift
//  VidCallApp
//

import SwiftUI
import ZegoExpressEngine
import FirebaseFirestore

struct VideoCallView: View {
    let roomID: String
    let userID: String
    let userName: String
    let remoteStreamID: String
    let onEndCall: () -> Void

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AppViewModel
    @StateObject private var callDurationManager = CallDurationManager.shared
    
    @State private var isMuted = false
    @State private var isCameraOn = true
    @State private var isUsingFrontCamera = true
    @State private var isCallConnected: Bool = false
    @State private var showTokenSheet = false
    @State private var receiverUID: String = ""
    @State private var receiverRate: Double = 5.0
    @State private var hasEndedCall = false
    @State private var callEndListener: ListenerRegistration?

    private let localView = UIView()
    private let remoteView = UIView()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VideoViewWrapper(view: remoteView)
                .ignoresSafeArea()

            // Local camera preview at the top right
            VStack {
                HStack {
                    Spacer()
                    VideoViewWrapper(view: localView)
                        .frame(width: 120, height: 180)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .padding(.trailing, 16)
                        .padding(.top, 60)
                }
                Spacer()
            }

            VStack {
                Spacer()
                
                // Call duration and cost display
                if isCallConnected && callDurationManager.isCallActive {
                    VStack(spacing: 4) {
                        // Show remaining time for customers, cost for providers
                        if let userProfile = viewModel.userProfile, userProfile.userType == .customer {
                            if callDurationManager.callData?.billingMode == .perMinute {
                                Text(callDurationManager.formatCallInfo(
                                    duration: callDurationManager.currentCallDuration,
                                    remainingTime: callDurationManager.remainingTime
                                ))
                                .font(.caption)
                                .foregroundColor(callDurationManager.isLowBalance ? .red : .white)
                                
                                if callDurationManager.isLowBalance {
                                    Text("Low balance warning!")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                }
                            }
                        } else {
                            // Provider view - show cost earned (75% of total)
                            Text(callDurationManager.formatDuration(callDurationManager.currentCallDuration))
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            let earnedAmount = callDurationManager.currentCallCost * 0.75
                            Text("Earned: \(callDurationManager.formatCost(earnedAmount))")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                }
                
                HStack(spacing: 16) {
                    Button(action: {
                        isMuted.toggle()
                        ZegoExpressEngine.shared().muteMicrophone(isMuted)
                    }) {
                        Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        endCall()
                    }) {
                        Image(systemName: "phone.down.fill")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.red)
                            .clipShape(Circle())
                    }

                    Button(action: {
                        isCameraOn.toggle()
                        ZegoExpressEngine.shared().enableCamera(isCameraOn)
                    }) {
                        Image(systemName: isCameraOn ? "video.fill" : "video.slash.fill")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        isUsingFrontCamera.toggle()
                        ZegoExpressEngine.shared().useFrontCamera(isUsingFrontCamera)
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Circle())
                    }

                    // $ Button for adding tokens (only for customers)
                    if let userProfile = viewModel.userProfile, userProfile.userType == .customer {
                        Button(action: {
                            showTokenSheet = true
                        }) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.green.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
                .cornerRadius(24)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            initializeZego()
            setupCallTracking()
            listenForCallEnd()
        }
        .onDisappear {
            if !hasEndedCall {
                endCall()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CallConnected"))) { _ in
            print("📞 CallConnected notification received")
            if !isCallConnected {
                isCallConnected = true
                startCallTracking()
            }
        }
        .sheet(isPresented: $showTokenSheet) {
            VStack(spacing: 20) {
                Text("Add Credits")
                    .font(.title)
                    .padding()
                
                Text("Add $20 to your balance")
                    .font(.headline)
                    .foregroundColor(.green)
                
                Button("Add $20") {
                    addCredits(amount: 20.0)
                    showTokenSheet = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Cancel") {
                    showTokenSheet = false
                }
                .foregroundColor(.red)
            }
            .padding()
        }
    }

    func initializeZego() {
        let user = ZegoUser(userID: userID, userName: userName)
        ZegoExpressEngine.shared().loginRoom(roomID, user: user)

        let localCanvas = ZegoCanvas()
        localCanvas.view = localView
        localCanvas.viewMode = .aspectFill
        ZegoExpressEngine.shared().startPreview(localCanvas)
        ZegoExpressEngine.shared().startPublishingStream("stream_\(userID)")

        let remoteCanvas = ZegoCanvas()
        remoteCanvas.view = remoteView
        remoteCanvas.viewMode = .aspectFill
        ZegoExpressEngine.shared().startPlayingStream(remoteStreamID, canvas: remoteCanvas)
    }
    
    func setupCallTracking() {
        // Extract receiver UID from remoteStreamID (format: "stream_UID")
        if remoteStreamID.hasPrefix("stream_") {
            receiverUID = String(remoteStreamID.dropFirst(7)) // Remove "stream_" prefix
            print("📞 Setting up call tracking for receiver: \(receiverUID)")
            
            // Get receiver's rate per minute
            let db = Firestore.firestore()
            db.collection("users").document(receiverUID).getDocument { snapshot, error in
                if let error = error {
                    print("❌ Error getting receiver rate: \(error.localizedDescription)")
                    return
                }
                
                if let data = snapshot?.data(),
                   let rate = data["ratePerMinute"] as? Double {
                    self.receiverRate = rate
                    print("💰 Receiver rate: $\(rate)/minute")
                }
            }
        }
    }
    
    func startCallTracking() {
        guard let callerUID = viewModel.userProfile?.uid else {
            print("❌ No caller UID available")
            return
        }
        
        print("🔄 startCallTracking called - callerUID: \(callerUID), receiverUID: \(receiverUID)")
        
        // Get customer credits for remaining time calculation
        let customerCredits = viewModel.userProfile?.credits ?? 0.0
        print("💰 Customer credits: $\(customerCredits)")
        
        callDurationManager.startCall(
            callerUID: callerUID,
            receiverUID: receiverUID,
            callerRate: 0, // No longer used, but required by signature
            receiverRate: 0, // No longer used, but required by signature
            roomID: roomID,
            customerCredits: customerCredits
        )
        print("📞 Call tracking started")
    }

    func endCall() {
        if hasEndedCall {
            print("📞 endCall() called but call already ended, returning")
            return
        }
        hasEndedCall = true
        
        print("📞 Ending call for room: \(roomID)")
        print("📞 User ID: \(userID), Remote Stream ID: \(remoteStreamID)")
        
        // Remove the call end listener to prevent further callbacks
        callEndListener?.remove()
        callEndListener = nil
        
        // Sync call end to other device (required for automatic call ending)
        callDurationManager.syncCallEnd(roomID: roomID, required: true)
        
        // End call tracking and deduct credits
        callDurationManager.endCall()
        
        // End Zego call
        print("🔌 Stopping Zego streams and logging out")
        ZegoExpressEngine.shared().stopPreview()
        ZegoExpressEngine.shared().stopPublishingStream()
        ZegoExpressEngine.shared().stopPlayingStream(remoteStreamID)
        ZegoExpressEngine.shared().logoutRoom(roomID)
        print("✅ Zego cleanup completed")
        
        // Ensure call request is deleted (for caller cancel before pickup)
        print("🧹 Calling CallManager.clearCall()")
        CallManager.shared.clearCall()
        
        // Also directly delete the call request document for the callee to ensure cleanup
        if !receiverUID.isEmpty {
            print("🧹 Directly deleting call request document for callee UID: \(receiverUID)")
            let db = Firestore.firestore()
            db.collection("callRequests").document(receiverUID).delete { error in
                if let error = error {
                    print("⚠️ Failed to directly delete call request for callee: \(error.localizedDescription)")
                } else {
                    print("✅ Call request document for callee directly deleted")
                }
            }
        }
        
        print("📞 Calling onEndCall()")
        onEndCall()
        print("✅ endCall() completed")
    }
    
    // MARK: - Listen for Call End from Other Device
    func listenForCallEnd() {
        let db = Firestore.firestore()
        
        callEndListener = db.collection("callEnds").document(roomID).addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Error listening for call end: \(error.localizedDescription)")
                return
            }
            
            if let data = snapshot?.data(), data["endedAt"] != nil {
                print("📞 Call end detected from other device")
                
                // Only end call if we haven't already ended it
                if !self.hasEndedCall {
                    DispatchQueue.main.async {
                        self.endCall()
                    }
                }
            }
        }
    }
    
    // MARK: - Add Credits Function
    func addCredits(amount: Double) {
        guard let user = viewModel.userProfile else {
            print("❌ No user profile available")
            return
        }
        
        let db = Firestore.firestore()
        
        // Update user credits
        db.collection("users").document(user.uid).updateData([
            "credits": FieldValue.increment(amount)
        ]) { error in
            if let error = error {
                print("❌ Error adding credits: \(error.localizedDescription)")
                return
            }
            
            print("✅ Added $\(amount) to user balance")
            
            // Create transaction record
            let transactionData: [String: Any] = [
                "userId": user.uid,
                "amount": amount,
                "paymentType": "credit_purchase",
                "status": "completed",
                "timestamp": FieldValue.serverTimestamp(),
                "username": user.username
            ]
            
            db.collection("transactions").addDocument(data: transactionData) { error in
                if let error = error {
                    print("❌ Error creating transaction record: \(error.localizedDescription)")
                } else {
                    print("✅ Transaction record created for credit purchase")
                }
            }
            
            // Refresh user profile to update UI
            DispatchQueue.main.async {
                self.viewModel.fetchUserProfile(for: user.uid)
                
                // Refresh call duration manager with new credits
                if let updatedProfile = self.viewModel.userProfile {
                    self.callDurationManager.refreshCustomerCredits(newCredits: updatedProfile.credits)
                }
            }
        }
    }
}

struct VideoViewWrapper: UIViewRepresentable {
    let view: UIView

    func makeUIView(context: Context) -> UIView {
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
