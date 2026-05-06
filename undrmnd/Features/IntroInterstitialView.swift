import SwiftUI

/// Intro screen with bundled Three.js particle background behind copy and continue (see `UndrmndApp`).
/// Only **Continue** is hit-tested; other touches pass through to the WebView so the nebula can react to touch.
struct IntroInterstitialView: View {
    var onContinue: () -> Void

    /// E‑reader‑toned parchment + grayscale torus; keep in sync with `ScanEffect/index.html` and `ScanEffectWebView`.
    private enum IntroEInkPaper {
        static let paperTop = Color(red: 244 / 255, green: 240 / 255, blue: 232 / 255)
        static let paperBottom = Color(red: 228 / 255, green: 223 / 255, blue: 212 / 255)
        static let vignetteWarm = Color(red: 218 / 255, green: 212 / 255, blue: 200 / 255)
        static let headline = Color(red: 48 / 255, green: 46 / 255, blue: 43 / 255)
        static let body = Color(red: 72 / 255, green: 69 / 255, blue: 62 / 255)
        static let ctaInk = UndrmndPrototypeTheme.accent
        static let ctaFill = Color.black.opacity(0.06)
        static let ctaStroke = Color.black.opacity(0.12)
    }

    /// WebGL readiness does not gate the splash; WKWebView is mounted after first frame so Cold launch stays responsive.
    @State private var scanBackgroundReady = true
    @State private var scanBackdropMounted = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [IntroEInkPaper.paperTop, IntroEInkPaper.paperBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if scanBackdropMounted {
                ScanEffectWebView(isBackgroundReady: $scanBackgroundReady)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }

            LinearGradient(
                colors: [
                    IntroEInkPaper.paperTop.opacity(0.2),
                    IntroEInkPaper.vignetteWarm.opacity(0.55)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 0)

                Text("undrmnd")
                    .font(AppFont.largeIntroTitle)
                    .foregroundStyle(IntroEInkPaper.headline)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .lineLimit(2)
                    .tracking(0.3)

                Text("Explore anything, the room is yours.")
                    .font(AppFont.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(IntroEInkPaper.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.8)
                    .lineSpacing(3)

                Spacer()
                    .frame(height: 64)
            }
            .frame(maxWidth: 340, maxHeight: .infinity, alignment: .bottom)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, 88)
            .allowsHitTesting(false)

            VStack {
                Spacer(minLength: 0)
                    .allowsHitTesting(false)
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(.body, design: .default))
                        .fontWeight(.semibold)
                        .foregroundStyle(IntroEInkPaper.ctaInk)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 9)
                        .background {
                            Capsule()
                                .fill(IntroEInkPaper.ctaFill)
                        }
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(IntroEInkPaper.ctaStroke, lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Continue into the app")
                .accessibilityHint("Dismisses this intro screen")
                .padding(.horizontal, 24)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .animation(.easeOut(duration: 0.45), value: scanBackgroundReady)
        .task {
            await Task.yield()
            scanBackdropMounted = true
        }
    }
}

#Preview {
    IntroInterstitialView(onContinue: {})
}
