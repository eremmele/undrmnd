import SafariServices
import SwiftUI

/// In-app browser for `source_url` / `action_url` handoff. No custom tracking layer in the app on top of Safari.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let c = SFSafariViewController(url: url)
        c.preferredControlTintColor = UIColor(UndrmndPrototypeTheme.primary)
        return c
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
