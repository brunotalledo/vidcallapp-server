//
//  TransactionRow.swift
//  VidCallApp
//
//  Created by Bruno Talledo on 4/30/25.
//


import SwiftUI

struct TransactionRow: View {
    let type: String
    let amount: String
    let date: String
    let isDebit: Bool
    let username: String
    let relatedUsername: String
    let callDuration: Int? // seconds
    let callRate: Double? // dollars per minute
    var condensed: Bool = false // NEW: for provider activity page
    private let appBlue = Color(red: 0, green: 0.8, blue: 1.0)

    var body: some View {
        HStack(alignment: .top, spacing: condensed ? 8 : 16) {
            if !condensed {
                // Transaction icon (only for non-condensed rows)
                Circle()
                    .fill(isDebit ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: isDebit ? "video.fill" : "plus.circle.fill")
                            .foregroundColor(isDebit ? .red : .green)
                    )
            }
            VStack(alignment: .leading, spacing: condensed ? 2 : 4) {
                if condensed {
                    // Condensed provider activity row
                    HStack(spacing: 4) {
                        Text("Customer:")
                            .foregroundColor(.white)
                            .font(.system(size: 13, weight: .semibold))
                        Text("@\(relatedUsername)")
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                    }
                } else {
                    Text(type)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                if (type == "Video Call" || type == "Call Earnings") && !condensed {
                    // For call transactions, show the person on the other end
                    if !relatedUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && relatedUsername != "Unknown" {
                        HStack(spacing: 4) {
                            Text("@\(relatedUsername)")
                                .foregroundColor(.gray)
                                .font(.system(size: 12))
                            if type == "Video Call" {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(appBlue)
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                    } else {
                        Text("Direct Transaction")
                            .foregroundColor(.gray)
                            .font(.system(size: 12))
                    }
                } else if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && username != "Unknown" && !condensed {
                    Text("@\(username)")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))
                }
                if type == "Video Call" || type == "Call Earnings" {
                    if let duration = callDuration, duration > 0 {
                        Text("Duration: \(formatDuration(duration))")
                            .foregroundColor(.white)
                            .font(.system(size: condensed ? 11 : 12))
                    }
                    if let rate = callRate, rate > 0 {
                        Text(String(format: "Rate: $%.2f/min", rate))
                            .foregroundColor(.white)
                            .font(.system(size: condensed ? 11 : 12))
                    }
                }
                Text(date)
                    .foregroundColor(.white)
                    .font(.system(size: condensed ? 12 : 14))
            }
            Spacer()
            Text(amount)
                .foregroundColor(isDebit ? .red : .green)
                .font(.system(size: condensed ? 14 : 16, weight: .semibold))
        }
        .padding(.vertical, condensed ? 2 : 4)
        .padding(.horizontal, condensed ? 0 : 0)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%dm %02ds", m, s)
    }
}
