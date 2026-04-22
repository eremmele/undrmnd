import SwiftUI

extension Pillar {
    /// Subtle full-bleed hero wash and branch stripe accent (kept light; hierarchy is still typographic).
    var articleChromeWash: Color {
        switch self {
        case .cosmos: return Color(red: 0.88, green: 0.9, blue: 0.96)
        case .livingWorld: return Color(red: 0.88, green: 0.95, blue: 0.9)
        case .mindAndBrain: return Color(red: 0.92, green: 0.9, blue: 0.96)
        case .howWeKnow: return Color(red: 0.94, green: 0.92, blue: 0.88)
        }
    }

    var articleStripe: Color {
        switch self {
        case .cosmos: return Color(red: 0.32, green: 0.38, blue: 0.58)
        case .livingWorld: return Color(red: 0.32, green: 0.52, blue: 0.42)
        case .mindAndBrain: return Color(red: 0.45, green: 0.38, blue: 0.58)
        case .howWeKnow: return Color(red: 0.52, green: 0.44, blue: 0.32)
        }
    }
}
