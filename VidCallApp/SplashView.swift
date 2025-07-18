//
//  Item.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/11/25.
//

import SwiftUI

struct SplashView: View {
    @State private var opacity = 0.0
    @State private var glowRadius: CGFloat = 20
    @State private var scale: CGFloat = 1.0
    @State private var flickerOpacity = 1.0
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                Circle()
                    .fill(.white)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .fill(appBlue)
                            .padding(20)
                            .overlay(
                                Text("V")
                                    .font(.system(size: 75, weight: .bold))
                                    .foregroundColor(.white)
                                    .offset(x: 3)
                            )
                    )
                    .shadow(color: appBlue.opacity(0.8), radius: glowRadius, x: 0, y: 0)
                    .opacity(opacity * flickerOpacity)
                    .scaleEffect(scale)

                Text("VIDDYCALL")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(appBlue)
                    .shadow(color: appBlue.opacity(0.5), radius: glowRadius * 0.5, x: 0, y: 0)
                    .opacity(opacity * flickerOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                self.opacity = 1.0
            }

            let pulseAnimation = Animation.easeInOut(duration: 0.5)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(pulseAnimation) { self.scale = 1.1; self.glowRadius = 35 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(pulseAnimation) { self.scale = 1.0; self.glowRadius = 20 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(pulseAnimation) { self.scale = 1.15; self.glowRadius = 40 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(pulseAnimation) { self.scale = 1.0; self.glowRadius = 20 }
                            let flickerDuration = 0.1
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: flickerDuration)) { self.flickerOpacity = 0.3 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + flickerDuration) {
                                    withAnimation(.easeInOut(duration: flickerDuration)) { self.flickerOpacity = 1.0 }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + flickerDuration) {
                                        withAnimation(.easeInOut(duration: flickerDuration)) { self.flickerOpacity = 0.5 }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + flickerDuration) {
                                            withAnimation(.easeInOut(duration: flickerDuration)) { self.flickerOpacity = 1.0 }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
