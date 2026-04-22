import Foundation

/// Remembers the last path the user opened so the Explore “Resume a path” affordance can continue it.
enum PathResumeStore {
    private static let key = "undrmnd.lastPathSlug"

    static var lastPathSlug: String? {
        UserDefaults.standard.string(forKey: key)
    }

    static func recordPathOpened(slug: String) {
        let t = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        UserDefaults.standard.set(t, forKey: key)
    }
}
