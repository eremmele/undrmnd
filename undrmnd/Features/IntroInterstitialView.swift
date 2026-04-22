import SwiftUI

/// Intro screen with bundled scan-effect (video + WebGL) behind copy and continue (see `UndrmndApp`).
/// Only **Continue** is hit-tested; other touches pass through for the scan touch highlight in the WebView.
struct IntroInterstitialView: View {
    var onContinue: () -> Void

    @State private var scanBackgroundReady = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            ScanEffectWebView(isBackgroundReady: $scanBackgroundReady)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.22),
                    Color.black.opacity(0.78)
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
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .lineLimit(2)
                    .tracking(0.3)

                Text("Explore anything, the room is yours.")
                    .font(AppFont.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.92))
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
                // Compact, glassy control — not full-bleed; white label on a soft blurred pill.
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(.subheadline, design: .default).weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 9)
                        .background {
                            ZStack {
                                Capsule()
                                    .fill(Color.white.opacity(0.07))
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.42)
                            }
                        }
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.24), lineWidth: 0.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Continue into the app")
                .accessibilityHint("Dismisses this intro screen")
                .padding(.horizontal, 24)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

            if !scanBackgroundReady {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.15)
                        Text("Preparing intro…")
                            .font(AppFont.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .allowsHitTesting(true)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Loading intro background")
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.45), value: scanBackgroundReady)
    }
}

#Preview {
    IntroInterstitialView(onContinue: {})
}
