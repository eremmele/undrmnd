import Foundation
import Supabase

// MARK: - RPC param structs (Supabase encodes snake_case keys)

private struct ListContributeThreadsParams: Encodable, Sendable {
    let pillar: String?
    let lim: Int
}

private struct GetContributeThreadParams: Encodable, Sendable {
    let thread_id: String
}

// MARK: - Errors

enum ContributeServiceError: Error, LocalizedError {
    case threadNotFound

    var errorDescription: String? {
        switch self {
        case .threadNotFound: return "Thread not found or no longer active."
        }
    }
}

// MARK: - Service

/// Reads seeded + user-written conversations from Supabase's
/// `contribute_threads` / `contribute_posts` tables via two RPCs.
enum ContributeService {

    /// All active threads, newest activity first. Pass `pillar == nil` for every pillar.
    static func listThreads(
        pillar: Pillar? = nil,
        limit: Int = 50,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [ContributeThread] {
        let params = ListContributeThreadsParams(pillar: pillar?.rawValue, lim: limit)
        let res: PostgrestResponse<[ContributeThread]> = try await client
            .rpc("list_contribute_threads", params: params)
            .execute()
        return res.value
    }

    /// Thread metadata + all posts, ordered by `created_at asc`.
    static func fetchThread(
        id: UUID,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> ContributeThreadBundle {
        let params = GetContributeThreadParams(thread_id: id.uuidString)
        let res: PostgrestResponse<ContributeThreadBundle> = try await client
            .rpc("get_contribute_thread", params: params)
            .execute()
        return res.value
    }
}
