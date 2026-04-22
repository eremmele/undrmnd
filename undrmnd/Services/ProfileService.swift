import Foundation
import Supabase

struct ContentListRow: Decodable, Identifiable, Hashable {
    let id: UUID
    let title: String
}

struct PathNodeRow: Decodable, Identifiable, Hashable {
    let id: UUID
    let pathId: UUID
    let branchPrompt: String?
    enum CodingKeys: String, CodingKey {
        case id
        case pathId = "path_id"
        case branchPrompt = "branch_prompt"
    }
}

private struct PathIdTitle: Decodable, Hashable {
    let id: UUID
    let title: String
}

enum ProfileService {
    static func fetchProfile(
        username: String,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> Profile {
        let res: PostgrestResponse<Profile> = try await client
            .from("profiles")
            .select()
            .eq("username", value: username)
            .single()
            .execute()
        return res.value
    }

    static func fetchMyProfile(
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> Profile? {
        guard let session = client.auth.currentSession, !session.isExpired else { return nil }
        let uid = session.user.id
        do {
            let res: PostgrestResponse<Profile> = try await client
                .from("profiles")
                .select()
                .eq("id", value: uid.uuidString)
                .single()
                .execute()
            return res.value
        } catch let error as PostgrestError {
            if error.code == "PGRST116" { return nil }
            throw error
        }
    }

    static func updateMyProfile(
        displayName: String?,
        bio: String?,
        pillarsFollowing: [Pillar],
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws {
        guard let session = client.auth.currentSession, !session.isExpired else {
            throw ProfileServiceError.notSignedIn
        }
        let body = ProfileUpdate(
            displayName: displayName,
            bio: bio,
            pillarsFollowing: pillarsFollowing
        )
        _ = try await client
            .from("profiles")
            .update(body)
            .eq("id", value: session.user.id.uuidString)
            .execute()
    }

    /// Creates a new profile row for the current auth user (RLS: `auth.uid() = id`).
    static func fetchContributedCards(
        username: String,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [ContentListRow] {
        let res: PostgrestResponse<[ContentListRow]> = try await client
            .from("content_items")
            .select("id, title")
            .eq("contributed_by", value: username)
            .eq("is_active", value: true)
            .execute()
        return res.value
    }

    static func fetchAuthoredPathNodes(
        username: String,
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [PathNodeRow] {
        let res: PostgrestResponse<[PathNodeRow]> = try await client
            .from("path_nodes")
            .select("id, path_id, branch_prompt")
            .eq("contributed_by", value: username)
            .execute()
        return res.value
    }

    static func pathTitles(
        for pathIds: [UUID],
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws -> [UUID: String] {
        guard !pathIds.isEmpty else { return [:] }
        let unique = Array(Set(pathIds))
        let res: PostgrestResponse<[PathIdTitle]> = try await client
            .from("paths")
            .select("id, title")
            .in("id", values: unique.map(\.uuidString))
            .execute()
        return Dictionary(uniqueKeysWithValues: res.value.map { ($0.id, $0.title) })
    }

    static func claimHandle(
        username: String,
        displayName: String?,
        bio: String?,
        pillarsFollowing: [Pillar],
        client: SupabaseClient = SupabaseService.shared.client
    ) async throws {
        guard let session = client.auth.currentSession, !session.isExpired else { throw ProfileServiceError.notSignedIn }
        let row = ProfileInsert(
            id: session.user.id,
            username: username,
            displayName: displayName,
            bio: bio,
            pillarsFollowing: pillarsFollowing
        )
        _ = try await client
            .from("profiles")
            .insert(row)
            .select()
            .execute()
    }
}

enum ProfileServiceError: Error, LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Not signed in."
        }
    }
}
