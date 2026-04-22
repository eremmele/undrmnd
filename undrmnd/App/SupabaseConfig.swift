import Foundation

/// Supabase project configuration. The publishable (anon) key is public in client apps;
/// access is enforced by RLS. Override with `SUPABASE_ANON_KEY` in the scheme for local/CI.
enum SupabaseConfig {
    static let url = URL(string: "https://ajxvmmdlqiijziveqaps.supabase.co")!
    private static let defaultPublishableKey = "sb_publishable_DInz61EAt396xQuZgDP_ZQ_qFAQv9r4"
    static var anonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? defaultPublishableKey
    }
}
