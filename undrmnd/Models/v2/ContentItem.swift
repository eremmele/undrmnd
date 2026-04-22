import Foundation

// MARK: - ContentItem (one card; full `content_items` row)

struct ContentItem: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let hook: String
    let body: String?
    let tags: [String]
    let interactionType: InteractionType
    let sourceCitation: String?
    let sourceUrl: String?
    let actionUrl: String?
    let topic: Pillar
    let estimatedTimeMinutes: Int?
    let isOpenQuestion: Bool
    let isActive: Bool
    let contributedBy: String?

    var sourceURL: URL? { sourceUrl.flatMap { URL(string: $0) } }
    var actionURL: URL? { actionUrl.flatMap { URL(string: $0) } }

    enum CodingKeys: String, CodingKey {
        case id, title, hook, body, tags, topic
        case interactionType = "interaction_type"
        case sourceCitation = "source_citation"
        case sourceUrl = "source_url"
        case actionUrl = "action_url"
        case estimatedTimeMinutes = "estimated_time_minutes"
        case isOpenQuestion = "is_open_question"
        case isActive = "is_active"
        case contributedBy = "contributed_by"
    }
}
