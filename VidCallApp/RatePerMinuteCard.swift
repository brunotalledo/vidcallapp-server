import SwiftUI

struct RatePerMinuteCard: View {
    let userProfile: UserProfile
    let appBlue: Color
    @Binding var showingRateEditSheet: Bool
    var onBillingModeChange: ((BillingMode) -> Void)? = nil

    @State private var selectedBillingMode: BillingMode

    init(userProfile: UserProfile, appBlue: Color, showingRateEditSheet: Binding<Bool>, onBillingModeChange: ((BillingMode) -> Void)? = nil) {
        self.userProfile = userProfile
        self.appBlue = appBlue
        self._showingRateEditSheet = showingRateEditSheet
        self.onBillingModeChange = onBillingModeChange
        self._selectedBillingMode = State(initialValue: userProfile.billingMode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rates")
                .foregroundColor(.white)
                .font(.caption)
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("$\(String(format: "%.2f", userProfile.ratePerMinute))/minute")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    if let sessionRate = userProfile.sessionRate {
                        Text("$\(String(format: "%.2f", sessionRate))/session")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                Button(action: {
                    showingRateEditSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                        Text("EDIT YOUR RATE")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [appBlue, Color(red: 0, green: 0.6, blue: 0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(appBlue, lineWidth: 1)
        )
        .padding(.horizontal)
    }
} 