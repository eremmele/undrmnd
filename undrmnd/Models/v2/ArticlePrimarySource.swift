import Foundation

struct ArticlePrimarySource: Decodable, Hashable, Sendable {
    let label: String
    let citation: String?
    let url: String?
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case label, citation, url
        case orderIndex = "order_index"
    }
}
