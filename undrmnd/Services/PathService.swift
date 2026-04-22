import Foundation
import Supabase

enum PathServiceError: Error, LocalizedError {
    case noActivePath

    var errorDescription: String? {
        switch self {
        case .noActivePath: return "No active path for this slug."
        }
    }
}

private struct GetPathParams: Encodable, Sendable {
    let path_slug: String
}

/// Loads tree/graph data for in-app `PathView` and `PathMapView`.
enum PathService {
    static func fetchPath(slug: String, client: SupabaseClient = SupabaseService.shared.client) async throws -> PathMap {
        let res: PostgrestResponse<PathMap> = try await client
            .rpc("get_path", params: GetPathParams(path_slug: slug))
            .execute()
        let map = res.value
        if map.path == nil {
            throw PathServiceError.noActivePath
        }
        return map
    }

    static func fetchActivePaths(
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [PathRecord] {
        let res: PostgrestResponse<[PathRecord]> = try await client
            .from("paths")
            .select()
            .eq("is_active", value: true)
            .order("title", ascending: true)
            .execute()
        return res.value
    }

    /// Featured paths for the home screen (newest first, capped in UI if needed).
    static func fetchFeaturedPaths(limit: Int = 10, client: SupabaseClient = SupabaseService.shared.client) async throws
        -> [PathRecord] {
        let res: PostgrestResponse<[PathRecord]> = try await client
            .from("paths")
            .select()
            .eq("is_featured", value: true)
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
        return res.value
    }
}
