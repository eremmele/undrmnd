import Foundation
import Supabase

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
