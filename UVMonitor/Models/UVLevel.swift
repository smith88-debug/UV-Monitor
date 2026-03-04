import SwiftUI

enum UVLevel: String {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
    case extreme = "Extreme"

    init(index: Double) {
        switch index {
        case ..<3: self = .low
        case 3..<6: self = .moderate
        case 6..<8: self = .high
        case 8..<11: self = .veryHigh
        default: self = .extreme
        }
    }

    var color: Color {
        switch self {
        case .low: .green
        case .moderate: .yellow
        case .high: .orange
        case .veryHigh: .red
        case .extreme: .purple
        }
    }

    var protectionAdvice: String {
        switch self {
        case .low:
            "No protection needed. Enjoy the outdoors!"
        case .moderate:
            "Wear sunscreen and a hat if outside for extended periods."
        case .high:
            "Sun protection required. Wear sunscreen, hat, and sunglasses."
        case .veryHigh:
            "Extra protection needed. Minimise sun exposure 10am–2pm."
        case .extreme:
            "Avoid being outside during midday hours. Full protection essential."
        }
    }

    var needsProtection: Bool {
        self != .low
    }
}
