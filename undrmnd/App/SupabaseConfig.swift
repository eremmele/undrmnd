import Foundation

/// Supabase project configuration. Anon key is read from environment variable
/// `SUPABASE_ANON_KEY` (set in Xcode: Edit Scheme → Run → Arguments → Environment Variables).
/// Fallback placeholder allows the project to build; replace or set env var for real usage.
enum SupabaseConfig {
    static let url = URL(string: "https://ajxvmmdlqiijziveqaps.supabase.co")!

    static var anonKey: String {
        ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
            ?? "REPLACE_WITH_YOUR_ANON_KEY"
    }
}
