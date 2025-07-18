//
//  ContentView.swift
//  VidCallApp
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @StateObject private var callManager = CallManager.shared
    @State private var isInCall = false
    @State private var showIncomingCall = false

    var body: some View {
        ZStack {
            if viewModel.isLoggedIn {
                ContactsView()
            } else {
                LoginView()
            }

            if showIncomingCall, let call = callManager.incomingCall {
                IncomingCallView(
                    callerName: call.callerName,
                    onAccept: {
                        isInCall = true
                        showIncomingCall = false
                    },
                    onDecline: {
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
                        print("🧼 Call ended (from VideoCallView in ContentView)")
                        isInCall = false
                        callManager.clearCall()
                    }
                )
                .onDisappear {
                    // No need to call endCall here anymore
                }
            }
        }
    }
}
