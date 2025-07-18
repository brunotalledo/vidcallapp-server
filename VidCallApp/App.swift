//
//  App.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 5/27/25.
//

import SwiftUI
import Firebase

@main
struct VidCallAppApp: App {
    @StateObject private var viewModel = AppViewModel()

    init() {
        FirebaseApp.configure()
        ZegoManager.shared.initialize(
            appID: 1166602555,
            appSign: "7604c62f805b8ac4e2c7e183cc2c8fb8ca3c5a001130a617c3766fd8d0a1a69d"
        )
    }

    var body: some Scene {
        WindowGroup {
            if viewModel.isLoggedIn {
                MainTabView()
                    .environmentObject(viewModel)
            } else {
                LoginView()
                    .environmentObject(viewModel)
            }
        }
    }
}

