import Foundation

struct CardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let hook: String
    let interactionType: String
}

