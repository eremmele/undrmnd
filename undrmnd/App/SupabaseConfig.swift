import Foundation

/// Supabase project configuration. Anon key is public-facing and safe to commit;
/// access is controlled by RLS policies. Replace with your project's anon key.
enum SupabaseConfig {
    static let url = URL(string: "https://ajxvmmdlqiijziveqaps.supabase.co")!
    static var anonKey: String {
        let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "MISSING_SUPABASE_ANON_KEY"
        return key
    }
}
