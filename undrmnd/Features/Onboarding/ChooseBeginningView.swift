import SwiftUI

/// Thumb-first fog entry: drifting fog fills the screen; search lives in the lower third (like `IntroInterstitialView`).
struct ChooseBeginningView: View {
    @EnvironmentObject private var onboarding: OnboardingCoordinator
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var searchText = ""

    /// Ink tuned for warm-tinted frosted glass over the night fog canvas (~4.5:1+ at body/caption sizes).
    private static let glassPrimaryText = Color(red: 0.11, green: 0.105, blue: 0.096)
    private static let glassMutedText = Color(red: 0.30, green: 0.292, blue: 0.282)

    private static let seededExamples: [String] = [
        "Dark matter & cosmology",
        "Speed of the universe (Hubble tension)",
        "How many species on Earth?",
        "Plants, fungi, and “wood-wide” claims",
        "Why phones are hard to put down",
        "Replication in psychology",
    ]

    /// Matches the outer sheet clip so the search band reads as one surface with the card (no square “cap”).
    private let cardCorner: CGFloat = 22
    /// Inset rows read as tiles on glass; slightly smaller than the shell so they don’t fight the shell radius.
    private let rowCorner: CGFloat = 12

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            LearningCommonsFogMapView(
                explorePath: .curiosityEntry(
                    typingRevealProgress: min(1, CGFloat(trimmedQuery.count) / 26)
                ),
                onThreadTap: nil
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 0) {
                    searchBand

                    Rectangle()
                        .fill(Self.glassPrimaryText.opacity(reduceTransparency ? 0.14 : 0.10))
                        .frame(height: 1)
                        .padding(.horizontal, 14)

                    bodyStack
                        .padding(14)
                }
                .background { fogGlassCardBackground }
                .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                        .strokeBorder(
                            UndrmndPrototypeTheme.divider.opacity(reduceTransparency ? 0.88 : 0.42),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.14), radius: 28, y: 16)
                .padding(.horizontal, 24)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.clear)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(FogMapShellChrome.mapInkSoft)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                FogGlassToolbarPillButton(systemName: "chevron.backward", accessibilityLabel: "Back to intro") {
                    onboarding.returnToInterstitial()
                }
            }
            ToolbarItem(placement: .principal) {
                FogToolbarPrincipalWordmark(useMaterialBackdrop: false)
            }
        }
    }

    private var searchBand: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Self.glassMutedText)
            TextField("Search a topic, question, hobby, or curiosity", text: $searchText)
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .foregroundStyle(Self.glassPrimaryText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
                .onSubmit(commitSearch)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var bodyStack: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Self.seededExamples, id: \.self) { label in
                    Button {
                        onboarding.submitSeed(label)
                    } label: {
                        HStack {
                            Text(label)
                                .font(AppFont.subheadline)
                                .foregroundStyle(Self.glassPrimaryText)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Self.glassMutedText)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background {
                            rowChromeBackground
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: rowCorner, style: .continuous)
                                .strokeBorder(UndrmndPrototypeTheme.divider.opacity(0.55), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: 220)
    }

    @ViewBuilder
    private var rowChromeBackground: some View {
        if reduceTransparency {
            RoundedRectangle(cornerRadius: rowCorner, style: .continuous)
                .fill(UndrmndPrototypeTheme.paper.opacity(0.75))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: rowCorner, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: rowCorner, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            }
        }
    }

    @ViewBuilder
    private var fogGlassCardBackground: some View {
        if reduceTransparency {
            RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                .fill(UndrmndPrototypeTheme.panel.opacity(0.96))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                    .fill(.ultraThinMaterial)
                warmGlassVeil
            }
        }
    }

    private var warmGlassVeil: some View {
        RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        UndrmndPrototypeTheme.paper.opacity(0.14),
                        UndrmndPrototypeTheme.paper.opacity(0.09)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private func commitSearch() {
        let q = trimmedQuery
        guard !q.isEmpty else { return }
        onboarding.submitSeed(q)
    }
}

#Preview {
    NavigationStack {
        ChooseBeginningView()
            .environmentObject(OnboardingCoordinator())
    }
}
