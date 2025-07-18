import SwiftUI

struct RateEditView: View {
    let currentRate: Double
    let currentSessionRate: Double?
    let currentBillingMode: BillingMode
    let onSave: (Double, Double?, BillingMode) -> Void
    let onCancel: () -> Void
    
    @State private var rateText: String
    @State private var sessionRateText: String
    @State private var selectedBillingMode: BillingMode
    @State private var showingError = false
    
    init(currentRate: Double, currentSessionRate: Double?, currentBillingMode: BillingMode, onSave: @escaping (Double, Double?, BillingMode) -> Void, onCancel: @escaping () -> Void) {
        self.currentRate = currentRate
        self.currentSessionRate = currentSessionRate
        self.currentBillingMode = currentBillingMode
        self.onSave = onSave
        self.onCancel = onCancel
        self._rateText = State(initialValue: String(format: "%.2f", currentRate))
        self._sessionRateText = State(initialValue: currentSessionRate != nil ? String(format: "%.2f", currentSessionRate!) : "")
        self._selectedBillingMode = State(initialValue: currentBillingMode)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Edit Rates")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rate per minute")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        HStack {
                            Text("$")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            TextField("0.00", text: $rateText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Flat session rate")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        HStack {
                            Text("$")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            TextField("0.00", text: $sessionRateText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            onCancel()
                        }) {
                            Text("Cancel")
                                .foregroundColor(.gray)
                                .font(.system(size: 12, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        Button(action: {
                            let rate = Double(rateText) ?? 0
                            let sessionRate = Double(sessionRateText)
                            let isPerMinuteValid = rate > 0
                            let isPerSessionValid = sessionRateText.isEmpty || (sessionRate != nil && sessionRate! > 0)
                            if isPerMinuteValid && isPerSessionValid {
                                onSave(rate, sessionRateText.isEmpty ? nil : sessionRate, currentBillingMode)
                            } else {
                                showingError = true
                            }
                        }) {
                            Text("Save")
                                .foregroundColor(.black)
                                .font(.system(size: 12, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(red: 0, green: 0.8, blue: 1.0))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .padding(.horizontal, 60)
            }
            .navigationBarHidden(true)
            .alert("Invalid Rate", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text("Please enter a valid rate greater than 0. For per session, leave blank if not used.")
            }
        }
    }
} 