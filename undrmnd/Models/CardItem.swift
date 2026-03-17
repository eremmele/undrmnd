import Foundation

struct CardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String
    let hook: String
    let interactionType: String
    let sourceUrl: String?
    let topic: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case hook
        case interactionType = "interaction_type"
        case sourceUrl = "source_url"
        case topic
    }
}

