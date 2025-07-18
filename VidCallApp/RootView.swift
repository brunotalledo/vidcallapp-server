//
//  Untitled.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/28/25.
//


import SwiftUI

struct RootView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showSplash = true

    var body: some View {
        Group {
            if showSplash {
                SplashView()
            } else {
                contentView
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoggedIn {
            MainTabView()  // ✅ Go to the MainTabView after login
        } else {
            LoginView()
        }
    }
}
