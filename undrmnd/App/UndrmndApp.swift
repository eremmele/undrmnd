import SwiftUI

@main
struct UndrmndApp: App {
    @StateObject private var onboarding = OnboardingCoordinator()

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                RootView()
                    .environmentObject(onboarding)
                    .environment(\.replayIntroSplashActive, onboarding.showReplayInterstitial)
                    .environment(\.colorScheme, .light)
                    .environment(\.returnToIntroSplash) {
                        onboarding.requestReplayIntroSplash()
                    }

                if onboarding.showReplayInterstitial {
                    IntroInterstitialView {
                        onboarding.dismissReplayIntroSplash()
                    }
                    .transition(.opacity)
                }
            }
            .environment(\.font, AppFont.body)
            .preferredColorScheme(.dark)
        }
    }
}
