//
//  ZegoManager.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 5/27/25.
//

import Foundation
import ZegoExpressEngine

class ZegoManager {
    static let shared = ZegoManager()

    private init() {}

    func initialize(appID: UInt32, appSign: String) {
        let profile = ZegoEngineProfile()
        profile.appID = appID
        profile.appSign = appSign
        profile.scenario = ZegoScenario(rawValue: 0)! // ✅ Replaces deprecated .communication

        ZegoExpressEngine.createEngine(with: profile, eventHandler: CustomZegoEventHandler.shared)
    }

    func loginRoom(roomID: String, userID: String, userName: String, completion: @escaping (Bool) -> Void) {
        let user = ZegoUser(userID: userID, userName: userName)
        let roomConfig = ZegoRoomConfig()
        ZegoExpressEngine.shared().loginRoom(roomID, user: user, config: roomConfig) { errorCode, _ in
            completion(errorCode == 0)
        }
    }

    func startPreview(view: UIView) {
        let canvas = ZegoCanvas(view: view)
        ZegoExpressEngine.shared().startPreview(canvas)
    }

    func startPlayingStream(streamID: String, view: UIView) {
        let canvas = ZegoCanvas(view: view)
        ZegoExpressEngine.shared().startPlayingStream(streamID, canvas: canvas)
    }

    func setVideoConfig() {
        let config = ZegoVideoConfig()
        config.captureResolution = CGSize(width: 640, height: 360)
        config.encodeResolution = CGSize(width: 640, height: 360)
        config.fps = 15
        config.bitrate = 600

        ZegoExpressEngine.shared().setVideoConfig(config)
    }

    func logoutRoom() {
        print("🔌 ZegoManager: Logging out from room")
        ZegoExpressEngine.shared().logoutRoom()
        print("✅ ZegoManager: Logout completed")
    }
}
