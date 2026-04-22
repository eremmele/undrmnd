import Foundation

struct ArticleBranch: Decodable, Hashable, Sendable, Identifiable {
    let id: UUID
    let title: String
    let prompt: String
    let contributionType: ArticleContributionType
    let orderIndex: Int
    let forkedArticleId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, title, prompt
        case contributionType = "contribution_type"
        case orderIndex = "order_index"
        case forkedArticleId = "forked_article_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        prompt = try c.decode(String.self, forKey: .prompt)
        let raw = try c.decode(String.self, forKey: .contributionType)
        contributionType = ArticleContributionType(rawValue: raw) ?? .observation
        orderIndex = try c.decode(Int.self, forKey: .orderIndex)
        forkedArticleId = try c.decodeIfPresent(UUID.self, forKey: .forkedArticleId)
    }
}
