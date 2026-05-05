import SwiftUI

@main
struct UndrmndApp: App {
    /// Shown on each new process launch until Continue. (In-memory for this run only, not UserDefaults, so a full quit and relaunch shows the splash again.)
    @State private var showIntroSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showIntroSplash {
                    IntroInterstitialView {
                        showIntroSplash = false
                    }
                } else {
                    RootView()
                }
            }
            .environment(\.font, AppFont.body)
        }
    }
}
