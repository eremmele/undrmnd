import Foundation

struct ArticleRelatedCard: Decodable, Hashable, Sendable {
    let contentId: UUID
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case contentId = "content_id"
        case orderIndex = "order_index"
    }
}
