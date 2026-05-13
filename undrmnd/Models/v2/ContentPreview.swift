import Foundation

/// Decodes a subset of the `content_items` row from `get_random_cards(n)` (no `body` or `estimated_time_minutes`).
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

    /// Explicit memberwise init, required because `init(from: ContentItem)` suppresses the synthesized one.
    init(
        id: UUID,
        title: String,
        hook: String,
        interactionType: InteractionType,
        sourceUrl: String?,
        actionUrl: String?,
        topic: Pillar,
        contributedBy: String?
    ) {
        self.id = id
        self.title = title
        self.hook = hook
        self.interactionType = interactionType
        self.sourceUrl = sourceUrl
        self.actionUrl = actionUrl
        self.topic = topic
        self.contributedBy = contributedBy
    }

    /// Maps a full `content_items` row to the light preview type used in sessions and lists.
    init(from item: ContentItem) {
        id = item.id
        title = item.title
        hook = item.hook
        interactionType = item.interactionType
        sourceUrl = item.sourceUrl
        actionUrl = item.actionUrl
        topic = item.topic
        contributedBy = item.contributedBy
    }

    /// Offline / empty-catalog fallback so three-card sessions still work when the RPC returns no active rows.
    /// IDs must match real `content_items` rows in Supabase that have active articles (see `get_article_for_card`).
    static let sessionFallback: [ContentPreview] = {
        let a = UUID(uuidString: "fd70d870-dc5b-42ed-b9c0-161f05fdb01d")!
        let b = UUID(uuidString: "db1826a6-623f-4e65-bb8d-cc7c09ebdaf0")!
        let c = UUID(uuidString: "617c1b37-21cd-44b9-b69f-a78d91e960d8")!
        return [
            ContentPreview(
                id: a,
                title: "What is dark matter, really?",
                hook: "85% of the matter in the universe is invisible, and no one knows what it's made of.",
                interactionType: .contribute,
                sourceUrl: nil,
                actionUrl: nil,
                topic: .cosmos,
                contributedBy: "teo_ok"
            ),
            ContentPreview(
                id: b,
                title: "Why is the replication crisis not a scandal?",
                hook: "Somewhere between 36% and 65% of published psychology findings don't replicate. That's not a failure — it's the system working.",
                interactionType: .read,
                sourceUrl: "https://doi.org/10.1126/science.aac4716",
                actionUrl: nil,
                topic: .howWeKnow,
                contributedBy: "ilhan_b"
            ),
            ContentPreview(
                id: c,
                title: "Is consciousness something physics can describe?",
                hook: "We don't have a theory that explains why there's a \"what it's like\" to be you.",
                interactionType: .reflect,
                sourceUrl: "https://doi.org/10.1038/s41586-023-06345-5",
                actionUrl: nil,
                topic: .mindAndBrain,
                contributedBy: "sage_m"
            )
        ]
    }()
}
