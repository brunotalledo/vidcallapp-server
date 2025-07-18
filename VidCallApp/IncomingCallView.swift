//
//  IncomingCallView.swift
//  VidCallApp
//

import SwiftUI

struct IncomingCallView: View {
    let callerName: String
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).edgesIgnoringSafeArea(.all)

            VStack(spacing: 24) {
                Text("Incoming Call")
                    .font(.largeTitle)
                    .foregroundColor(.white)

                Text("\(callerName) is calling...")
                    .font(.title2)
                    .foregroundColor(.gray)

                HStack(spacing: 50) {
                    Button(action: onDecline) {
                        Image(systemName: "phone.down.fill")
                            .padding()
                            .background(Color.red)
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }

                    Button(action: onAccept) {
                        Image(systemName: "phone.fill")
                            .padding()
                            .background(Color.green)
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}
