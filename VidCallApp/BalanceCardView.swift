import SwiftUI

struct BalanceCardView: View {
    let balanceLabel: String
    let balance: Double
    let appBlue: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(balanceLabel)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            Text("$\(String(format: "%.2f", balance))")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 64)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(appBlue, lineWidth: 1)
        )
        .padding(.horizontal, 8)
    }
} 
