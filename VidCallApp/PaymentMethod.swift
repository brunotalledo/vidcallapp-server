import Foundation

struct PaymentMethod: Identifiable {
    let id: String // token
    let type: String
    let last4: String?
    let cardType: String?
    let expirationMonth: String?
    let expirationYear: String?
    let isDefault: Bool
    
    init(token: String, type: String, last4: String?, cardType: String?, expirationMonth: String?, expirationYear: String?, isDefault: Bool = false) {
        self.id = token
        self.type = type
        self.last4 = last4
        self.cardType = cardType
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.isDefault = isDefault
    }
    
    init?(from dictionary: [String: Any]) {
        guard let token = dictionary["token"] as? String,
              let type = dictionary["type"] as? String else {
            return nil
        }
        
        self.id = token
        self.type = type
        self.last4 = dictionary["last4"] as? String
        self.cardType = dictionary["cardType"] as? String
        self.expirationMonth = dictionary["expirationMonth"] as? String
        self.expirationYear = dictionary["expirationYear"] as? String
        self.isDefault = dictionary["isDefault"] as? Bool ?? false
    }
    
    var displayName: String {
        switch type.lowercased() {
        case "credit_card":
            if let cardType = cardType, let last4 = last4 {
                return "\(cardType) •••• \(last4)"
            } else if let last4 = last4 {
                return "Card •••• \(last4)"
            } else {
                return "Credit Card"
            }
        case "paypal":
            return "PayPal"
        case "apple_pay":
            return "Apple Pay"
        case "venmo":
            return "Venmo"
        default:
            return type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    var expirationDisplay: String {
        if let month = expirationMonth, let year = expirationYear {
            return "\(month)/\(year)"
        }
        return ""
    }
} 