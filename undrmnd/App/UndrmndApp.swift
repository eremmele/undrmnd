import SwiftUI

@main
struct UndrmndApp: App {
    /// Shown on each new process launch until Continue. (In-memory for this run only, not UserDefaults, so a full quit and relaunch shows the splash again.)
    @State private var showIntroSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                Group {
                    if showIntroSplash {
                        IntroInterstitialView {
                            showIntroSplash = false
                        }
                    } else {
                        // Main chrome is paper-toned prototypes; forcing light mode here keeps semantic
                        // `.primary`/field defaults legible against `UndrmndPrototypeTheme.paper` even though
                        // the window prefers dark for the intro WebGL shell.
                        RootView()
                            .environment(\.colorScheme, .light)
                            .environment(\.returnToIntroSplash) {
                                showIntroSplash = true
                            }
                    }
                }
            }
            .environment(\.font, AppFont.body)
            .preferredColorScheme(.dark)
        }
    }
}
