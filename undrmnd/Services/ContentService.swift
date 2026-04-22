import Foundation
import Supabase

private struct RandomCardsParams: Encodable, Sendable {
    let n: Int
}

enum ContentService {
    static func fetchRandomCards(
        n: Int = 3,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [ContentPreview] {
        let res: PostgrestResponse<[ContentPreview]> = try await client
            .rpc("get_random_cards", params: RandomCardsParams(n: n))
            .execute()
        return res.value
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
}
