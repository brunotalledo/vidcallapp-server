//
//  ZegoExpressEventHandler.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 5/25/25.
//

import ZegoExpressEngine
import UIKit

class CustomZegoEventHandler: NSObject, ZegoEventHandler {
    static let shared = CustomZegoEventHandler()

    override private init() {
        super.init()
        ZegoExpressEngine.shared().setEventHandler(self)
    }

    // Standard Zego event handler for stream updates
    func onRoomStreamUpdate(_ updateType: ZegoUpdateType, streamList: [ZegoStream], extendedData: [AnyHashable : Any]?, roomID: String) {
        if updateType == .add {
            for stream in streamList {
                print("[ZegoEventHandler] Stream added: \(stream.streamID)")
                // Notify that the call is connected (remote stream received)
                NotificationCenter.default.post(name: Notification.Name("CallConnected"), object: nil)
                // Do NOT add any UIViews here. Just log or trigger logic if needed.
                // The SwiftUI VideoViewWrapper in VideoCallView will handle video display.
            }
        } else if updateType == .delete {
            for stream in streamList {
                print("[ZegoEventHandler] Stream removed: \(stream.streamID)")
                // Do NOT remove any UIViews here. Just log or trigger logic if needed.
            }
        }
    }

    // Optionally, implement other ZegoEventHandler methods as needed
}
