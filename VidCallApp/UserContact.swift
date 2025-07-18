//
//  UserContact.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 5/25/25.
//

import Foundation

struct ContactImageData {
    var imageData: Data?
    var initials: String?

    init(imageData: Data? = nil, initials: String? = nil) {
        self.imageData = imageData
        self.initials = initials
    }

    static func initials(_ letters: String) -> ContactImageData {
        return ContactImageData(initials: letters)
    }
}

struct UserContact: Identifiable {
    var id: String
    var name: String
    var subtitle: String
    var imageData: ContactImageData
    var ratePerMinute: Double?
    var sessionRate: Double?
    var billingMode: BillingMode?
}
