import Foundation

// MARK: - AppSession (local / future sync; renames avoid clash with `Auth.Session` from Supabase)

struct AppSession: Codable, Identifiable, Hashable {
    let id: UUID
    let userId: UUID
    let startedAt: Date
    let completedAt: Date?
    let status: String
    let cardsServedCount: Int
    let cardsCompletedCount: Int

    enum CodingKeys: String, CodingKey {
        case id, status
        case userId = "user_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case cardsServedCount = "cards_served_count"
        case cardsCompletedCount = "cards_completed_count"
    }
}
