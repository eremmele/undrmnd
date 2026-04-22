import Foundation

struct Article: Decodable, Identifiable, Hashable, Sendable {
    let id: UUID
    let contentId: UUID
    let slug: String
    let title: String
    let pillar: Pillar
    let authorHandle: String
    let authorUserId: UUID?
    let bylineRole: String?
    let heroCaption: String?
    let heroImageUrl: String?
    let heroImagePrompt: String?
    let heroImageSource: String?
    let parentArticleId: UUID?
    let parentVersionId: UUID?
    let currentVersionId: UUID
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case contentId = "content_id"
        case slug, title, pillar
        case authorHandle = "author_handle"
        case authorUserId = "author_user_id"
        case bylineRole = "byline_role"
        case heroCaption = "hero_caption"
        case heroImageUrl = "hero_image_url"
        case heroImagePrompt = "hero_image_prompt"
        case heroImageSource = "hero_image_source"
        case parentArticleId = "parent_article_id"
        case parentVersionId = "parent_version_id"
        case currentVersionId = "current_version_id"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        contentId = try c.decode(UUID.self, forKey: .contentId)
        slug = try c.decode(String.self, forKey: .slug)
        title = try c.decode(String.self, forKey: .title)
        let pillarRaw = try c.decode(String.self, forKey: .pillar)
        pillar = Pillar(rawValue: pillarRaw) ?? .cosmos
        authorHandle = try c.decode(String.self, forKey: .authorHandle)
        authorUserId = try c.decodeIfPresent(UUID.self, forKey: .authorUserId)
        bylineRole = try c.decodeIfPresent(String.self, forKey: .bylineRole)
        heroCaption = try c.decodeIfPresent(String.self, forKey: .heroCaption)
        heroImageUrl = try c.decodeIfPresent(String.self, forKey: .heroImageUrl)
        heroImagePrompt = try c.decodeIfPresent(String.self, forKey: .heroImagePrompt)
        heroImageSource = try c.decodeIfPresent(String.self, forKey: .heroImageSource)
        parentArticleId = try c.decodeIfPresent(UUID.self, forKey: .parentArticleId)
        parentVersionId = try c.decodeIfPresent(UUID.self, forKey: .parentVersionId)
        currentVersionId = try c.decode(UUID.self, forKey: .currentVersionId)
        isActive = try c.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
}
