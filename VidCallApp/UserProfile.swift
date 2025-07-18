//
//  UserProfile.swift
//

import Foundation

enum UserType: String, Codable {
    case provider
    case customer
}

enum BillingMode: String, Codable {
    case perMinute = "per_minute"
    case perSession = "per_session"
}

struct UserProfile: Codable {
    let uid: String
    let email: String
    let username: String
    let contacts: [String]
    let credits: Double // Changed from Int to Double to support decimal values
    let ratePerMinute: Double // How much this user charges per minute
    let sessionRate: Double? // Flat rate for a session (optional)
    let billingMode: BillingMode // Which billing mode is active
    let userType: UserType
    let isAvailable: Bool // Whether the provider is available for calls
    let blockedUsers: [String] // Array of blocked user UIDs
    let paypalEmail: String? // Optional PayPal email for payouts
}
