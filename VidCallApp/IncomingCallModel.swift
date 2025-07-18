//
//  IncomingCallModel.swift
//  VidCallApp
//

import Foundation

struct IncomingCall: Codable, Identifiable {
    let callerID: String
    let callerName: String
    let roomID: String

    var id: String {
        return roomID
    }

    enum CodingKeys: String, CodingKey {
        case callerID
        case callerName
        case roomID
    }
}
