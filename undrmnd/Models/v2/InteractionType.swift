import Foundation

// MARK: - Interaction types (ways in)

enum InteractionType: String, Codable, CaseIterable, Hashable {
    case read
    case reflect
    case observe
    case contribute

    var verb: String {
        switch self {
        case .read: return "Read"
        case .reflect: return "Reflect"
        case .observe: return "Notice"
        case .contribute: return "Contribute"
        }
    }
}
