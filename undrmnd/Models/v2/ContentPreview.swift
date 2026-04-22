import Foundation

/// Row shape returned by `get_random_cards(n)` — no `body` or `estimated_time_minutes`.
struct ContentPreview: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let hook: String
    let interactionType: InteractionType
    let sourceUrl: String?
    let actionUrl: String?
    let topic: Pillar
    let contributedBy: String?

    enum CodingKeys: String, CodingKey {
        case id, title, hook, topic, contributedBy = "contributed_by"
        case interactionType = "interaction_type"
        case sourceUrl = "source_url"
        case actionUrl = "action_url"
    }
}
