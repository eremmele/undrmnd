import Foundation

// MARK: - PathRecord (row in `paths`; named to avoid clashing with `SwiftUI.Path`)

struct PathRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let slug: String
    let title: String
    let subtitle: String?
    let topic: Pillar
    let isActive: Bool
    let isFeatured: Bool
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, slug, title, subtitle, topic
        case isActive = "is_active"
        case isFeatured = "is_featured"
        case createdAt = "created_at"
    }
}
