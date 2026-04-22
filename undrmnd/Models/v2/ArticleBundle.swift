import Foundation

struct ArticleBundle: Decodable, Hashable, Sendable {
    let article: Article
    let version: ArticleVersion
    let primarySources: [ArticlePrimarySource]
    let branches: [ArticleBranch]
    let relatedCards: [ArticleRelatedCard]

    enum CodingKeys: String, CodingKey {
        case article, version, branches
        case primarySources = "primary_sources"
        case relatedCards = "related_cards"
    }
}
