import Foundation

struct ArticleVersion: Decodable, Identifiable, Hashable, Sendable {
    let id: UUID
    let articleId: UUID
    let parentVersionId: UUID?
    let versionNumber: Int
    let bodyMarkdown: String
    let commitMessage: String?
    let authorHandle: String
    let authorUserId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case articleId = "article_id"
        case parentVersionId = "parent_version_id"
        case versionNumber = "version_number"
        case bodyMarkdown = "body_markdown"
        case commitMessage = "commit_message"
        case authorHandle = "author_handle"
        case authorUserId = "author_user_id"
        case createdAt = "created_at"
    }
}
