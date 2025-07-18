//
//  Untitled.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/28/25.
//


import SwiftUI
import FirebaseFirestore

struct MainTabView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @StateObject private var callManager = CallManager.shared
    @State private var isInCall = false
    @State private var showIncomingCall = false
    @State private var selectedTab = 0  // Default to Profile tab first
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)

    var body: some View {
        TabView(selection: $selectedTab) {
            PaymentView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(0)
            
            ContactsView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Contacts")
                }
                .tag(1)
            
            ActivityView()
                .tabItem {
                    Image(systemName: "clock")
                    Text("Activity")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(appBlue)
        .preferredColorScheme(.dark)
        .onAppear {
            if let uid = viewModel.userProfile?.uid {
                print("🔍 MainTabView onAppear - User UID: \(uid)")
                // Removed callRequests document deletion here
                print("👂 (MainTabView) Setting up listener for: \(uid)")
                IncomingCallListener.shared.startListening(for: uid) { call in
                    print("📞 MainTabView callback received - call: \(call?.callerName ?? "nil")")
                    if let call = call {
                        print("📥 Incoming call from \(call.callerName) in room \(call.roomID)")
                        DispatchQueue.main.async {
                            print("🎯 Setting incoming call in CallManager")
                            callManager.incomingCall = call
                            showIncomingCall = true
                            print("🎯 showIncomingCall set to true")
                        }
                    } else {
                        print("⚠️ Incoming call listener triggered, but call data was nil (call ended or declined).")
                        DispatchQueue.main.async {
                            print("🧹 Cleaning up call UI and Zego connection")
                            print("   - Current showIncomingCall: \(showIncomingCall)")
                            print("   - Current isInCall: \(isInCall)")
                            print("   - Current incomingCall: \(callManager.incomingCall?.callerName ?? "nil")")
                            
                            // Force cleanup of all call-related state
                            ZegoManager.shared.logoutRoom() // Leave Zego room if still ringing
                            callManager.incomingCall = nil
                            showIncomingCall = false
                            isInCall = false // Ensure call view is dismissed
                            
                            // Force UI update by triggering a small delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showIncomingCall = false
                                isInCall = false
                                print("🔄 Forced UI state reset")
                            }
                            
                            print("✅ Call cleanup completed")
                            print("   - New showIncomingCall: \(showIncomingCall)")
                            print("   - New isInCall: \(isInCall)")
                        }
                    }
                }
            }
        }
        .onChange(of: viewModel.userProfile?.uid) { oldUID, newUID in
            if let uid = newUID {
                // Removed callRequests document deletion here
                print("👂 (MainTabView) Setting up listener for: \(uid)")
                IncomingCallListener.shared.startListening(for: uid) { call in
                    if let call = call {
                        print("📥 Incoming call from \(call.callerName) in room \(call.roomID)")
                        DispatchQueue.main.async {
                            callManager.incomingCall = call
                            showIncomingCall = true
                        }
                    } else {
                        print("⚠️ Incoming call listener triggered, but call data was nil (call ended or declined).")
                        DispatchQueue.main.async {
                            print("🧹 Cleaning up call UI and Zego connection (onChange)")
                            print("   - Current showIncomingCall: \(showIncomingCall)")
                            print("   - Current isInCall: \(isInCall)")
                            print("   - Current incomingCall: \(callManager.incomingCall?.callerName ?? "nil")")
                            
                            // Force cleanup of all call-related state
                            ZegoManager.shared.logoutRoom() // Leave Zego room if still ringing
                            callManager.incomingCall = nil
                            showIncomingCall = false
                            isInCall = false // Ensure call view is dismissed
                            
                            // Force UI update by triggering a small delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showIncomingCall = false
                                isInCall = false
                                print("🔄 Forced UI state reset (onChange)")
                            }
                            
                            print("✅ Call cleanup completed (onChange)")
                            print("   - New showIncomingCall: \(showIncomingCall)")
                            print("   - New isInCall: \(isInCall)")
                        }
                    }
                }
            }
        }
        .overlay(
            Group {
                if showIncomingCall, let call = callManager.incomingCall {
                    IncomingCallView(
                        callerName: call.callerName,
                        onAccept: {
                            print("✅ Call accepted")
                            isInCall = true
                            showIncomingCall = false
                        },
                        onDecline: {
                            print("❌ Call declined")
                            showIncomingCall = false
                            callManager.clearCall()
                        }
                    )
                }
                if isInCall, let call = callManager.incomingCall {
                    VideoCallView(
                        roomID: call.roomID,
                        userID: viewModel.userProfile?.uid ?? UUID().uuidString,
                        userName: viewModel.userProfile?.username ?? "Unknown",
                        remoteStreamID: "stream_\(call.callerID)",
                        onEndCall: {
                            print("🧼 Call ended (from VideoCallView)")
                            isInCall = false
                            callManager.clearCall()
                        }
                    )
                    .onDisappear {
                        // No need to call endCall here anymore
                    }
                }
            }
        )
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}
