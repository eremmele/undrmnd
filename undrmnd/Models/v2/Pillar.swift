import Foundation

// MARK: - Pillars

enum Pillar: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case cosmos = "cosmos"
    case livingWorld = "living_world"
    case mindAndBrain = "mind_and_brain"
    case howWeKnow = "how_we_know"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cosmos: return "Cosmos"
        case .livingWorld: return "Living World"
        case .mindAndBrain: return "Mind & Brain"
        case .howWeKnow: return "How We Know"
        }
    }
}
