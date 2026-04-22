import SwiftUI

@main
struct UndrmndApp: App {
    /// Shown on each new process launch until Continue. (Persists only for this run — not UserDefaults — so you always see the splash after a full quit and relaunch.)
    @State private var showIntroSplash = true

    init() {
        ScanEffectVideoPrewarmer.prewarmBundledVideo()
    }

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
