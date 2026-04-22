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

    /// Explicit memberwise init — required because `init(from: ContentItem)` suppresses the synthesized one.
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
    static let sessionFallback: [ContentPreview] = {
        // Placeholder UUIDs — detail fetches will fail silently; card copy still works from preview fields.
        let a = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let b = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let c = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        return [
            ContentPreview(
                id: a,
                title: "What is dark matter, really?",
                hook: "85% of the matter in the universe is invisible, and no one knows what it’s made of.",
                interactionType: .read,
                sourceUrl: nil,
                actionUrl: nil,
                topic: .cosmos,
                contributedBy: "teo_ok"
            ),
            ContentPreview(
                id: b,
                title: "How many species share Earth with us? No one knows within a factor of 10.",
                hook: "Estimates range from 2 million to a trillion. Most of the uncertainty is microbes.",
                interactionType: .read,
                sourceUrl: nil,
                actionUrl: nil,
                topic: .livingWorld,
                contributedBy: "nneka_o"
            ),
            ContentPreview(
                id: c,
                title: "Why is the replication crisis not a scandal?",
                hook: "Somewhere between 36% and 65% of published psychology findings don’t replicate. That’s not a failure — it’s the system working.",
                interactionType: .reflect,
                sourceUrl: nil,
                actionUrl: nil,
                topic: .howWeKnow,
                contributedBy: "ilhan_b"
            )
        ]
    }()
}
