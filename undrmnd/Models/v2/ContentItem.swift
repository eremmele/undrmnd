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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        hook = try c.decode(String.self, forKey: .hook)
        body = try c.decodeIfPresent(String.self, forKey: .body)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        interactionType = try c.decode(InteractionType.self, forKey: .interactionType)
        sourceCitation = try c.decodeIfPresent(String.self, forKey: .sourceCitation)
        sourceUrl = try c.decodeIfPresent(String.self, forKey: .sourceUrl)
        actionUrl = try c.decodeIfPresent(String.self, forKey: .actionUrl)
        topic = try c.decode(Pillar.self, forKey: .topic)
        estimatedTimeMinutes = try c.decodeIfPresent(Int.self, forKey: .estimatedTimeMinutes)
        isOpenQuestion = try c.decodeIfPresent(Bool.self, forKey: .isOpenQuestion) ?? true
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        contributedBy = try c.decodeIfPresent(String.self, forKey: .contributedBy)
    }
}
