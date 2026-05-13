import Foundation

/// Row inside `related_cards` from `get_article_for_card` / `get_article` (shape varies by SQL aliases).
struct ArticleRelatedCard: Decodable, Hashable, Sendable {
    let contentId: UUID
    let orderIndex: Int
    /// First non-empty title-like string found on the payload (flat keys or nested `content_items` / `content_item`).
    let previewTitle: String?

    private enum CodingKeys: String, CodingKey {
        case contentId = "content_id"
        case orderIndex = "order_index"
        case title
        case cardTitle = "card_title"
        case contentTitle = "content_title"
        case previewTitleSnake = "preview_title"
        case cardHook = "card_hook"
        case hook
        case headline
        case contentItem = "content_item"
        case contentItems = "content_items"
    }

    /// Minimal nested copy of `content_items` when the RPC embeds a row or `{ title, hook }`.
    private struct NestedCardCopy: Decodable {
        let title: String?
        let hook: String?
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        contentId = try c.decode(UUID.self, forKey: .contentId)
        orderIndex = try c.decode(Int.self, forKey: .orderIndex)

        let flatCandidates: [String?] = [
            try c.decodeIfPresent(String.self, forKey: .title),
            try c.decodeIfPresent(String.self, forKey: .cardTitle),
            try c.decodeIfPresent(String.self, forKey: .contentTitle),
            try c.decodeIfPresent(String.self, forKey: .previewTitleSnake),
            try c.decodeIfPresent(String.self, forKey: .cardHook),
            try c.decodeIfPresent(String.self, forKey: .hook),
            try c.decodeIfPresent(String.self, forKey: .headline),
        ]

        let nested: NestedCardCopy?
        if let item = try c.decodeIfPresent(NestedCardCopy.self, forKey: .contentItem) {
            nested = item
        } else {
            nested = try c.decodeIfPresent(NestedCardCopy.self, forKey: .contentItems)
        }

        let nestedTitle: String? = {
            guard let nested else { return nil }
            if let t = nested.title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty { return t }
            if let h = nested.hook?.trimmingCharacters(in: .whitespacesAndNewlines), !h.isEmpty { return h }
            return nil
        }()

        previewTitle = Self.firstNonEmpty(flatCandidates + [nestedTitle])
    }

    private static func firstNonEmpty(_ strings: [String?]) -> String? {
        for raw in strings {
            guard let raw else { continue }
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        return nil
    }
}
