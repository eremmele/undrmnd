import Foundation
import Supabase

/// Single Supabase client for the app. Use via shared instance or inject as environment object.
final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    var auth: AuthClient { client.auth }
    var storage: SupabaseStorageClient { client.storage }
    var rest: PostgrestClient { client.rest }
    var realtime: RealtimeClientV2 { client.realtimeV2 }
    var functions: FunctionsClient { client.functions }
}
