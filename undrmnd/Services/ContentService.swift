import Foundation
import Supabase

private struct RandomCardsParams: Encodable, Sendable {
    let n: Int
}

private struct SearchContentItemsParams: Encodable, Sendable {
    let search_query: String
    let result_limit: Int
}

enum ContentService {
    /// - Parameter padWithSessionFallback: When true (default), pad short RPC results with `ContentPreview.sessionFallback` for offline demos. Set **false** for map/onboarding so every id is a real `content_items` row.
    static func fetchRandomCards(
        n: Int = 3,
        padWithSessionFallback: Bool = true,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [ContentPreview] {
        let res: PostgrestResponse<[ContentItem]> = try await client
            .rpc("get_random_cards", params: RandomCardsParams(n: n))
            .execute()
        var rows = res.value.map { ContentPreview(from: $0) }
        if padWithSessionFallback, rows.count < n {
            let need = n - rows.count
            let extras = ContentPreview.sessionFallback.filter { f in
                !rows.contains { $0.id == f.id }
            }
            rows.append(contentsOf: extras.prefix(need))
        }
        return Array(rows.prefix(n))
    }

    static func fetchCardDetail(
        id: UUID,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> ContentItem {
        let res: PostgrestResponse<ContentItem> = try await client
            .from("content_items")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
        return res.value
    }

    /// Curiosity / map entry: match contributed `content_items` by title or hook (`search_content_items` RPC).
    static func searchContentItems(
        query: String,
        limit: Int = 12,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [ContentItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard q.count >= 2 else { return [] }
        let res: PostgrestResponse<[ContentItem]> = try await client
            .rpc(
                "search_content_items",
                params: SearchContentItemsParams(search_query: q, result_limit: min(max(limit, 1), 24))
            )
            .execute()
        return res.value
    }
}
