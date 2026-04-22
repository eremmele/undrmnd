import SafariServices
import SwiftUI

/// In-app browser for `source_url` / `action_url` handoff; no data leaves the device through custom trackers.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let c = SFSafariViewController(url: url)
        c.preferredControlTintColor = UIColor(UndrmndPrototypeTheme.primary)
        return c
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
