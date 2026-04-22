import Foundation

// MARK: - ContributeThread
//
// Mirrors the row shape returned by the `list_contribute_threads(pillar, lim)` RPC.
// Also sufficient for decoding a single thread from the `get_contribute_thread(id)`
// JSON envelope (`thread` key) — that envelope omits `post_count`/`last_post_*`,
// so those fields are optional.

struct ContributeThread: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let topic: Pillar
    let createdByHandle: String
    let createdAt: Date
    let updatedAt: Date

    // Only present when fetched via `list_contribute_threads`.
    let postCount: Int?
    let lastPostHandle: String?
    let lastPostAt: Date?

    // Only present when fetched directly from `contribute_threads` or inside
    // the `get_contribute_thread` envelope.
    let isActive: Bool?
    let createdByUserId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, title, topic
        case createdByHandle = "created_by_handle"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case postCount = "post_count"
        case lastPostHandle = "last_post_handle"
        case lastPostAt = "last_post_at"
        case isActive = "is_active"
        case createdByUserId = "created_by_user_id"
    }
}
