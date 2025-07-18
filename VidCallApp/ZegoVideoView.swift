//
//  ZegoVideoView.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 5/27/25.
//

import SwiftUI
import ZegoExpressEngine

struct ZegoLocalVideoView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let canvas = ZegoCanvas(view: uiView)
        canvas.viewMode = .aspectFill
        ZegoExpressEngine.shared().startPreview(canvas)
    }
}

struct ZegoRemoteVideoView: UIViewRepresentable {
    let streamID: String

    func makeUIView(context: Context) -> UIView {
        return UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let canvas = ZegoCanvas(view: uiView)
        canvas.viewMode = .aspectFill
        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
    }
}
