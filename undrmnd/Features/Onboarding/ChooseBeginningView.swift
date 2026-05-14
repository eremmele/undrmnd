import SwiftUI

/// Thumb-first fog entry: drifting fog fills the screen; search lives in the lower third (like `IntroInterstitialView`).
struct ChooseBeginningView: View {
    @EnvironmentObject private var onboarding: OnboardingCoordinator
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool

    /// Dark “command palette” ink over the fog map (WCAG-friendly on charcoal panels).
    private static let darkPrimaryText = Color(red: 0.93, green: 0.91, blue: 0.87)
    private static let darkMutedText = Color(red: 0.62, green: 0.60, blue: 0.56)
    private static let darkCardFill = Color(red: 0.12, green: 0.12, blue: 0.13)
    private static let darkRowFill = Color(red: 0.17, green: 0.17, blue: 0.18)
    private static let darkHairline = Color.white.opacity(0.10)

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
                        .fill(Self.darkHairline)
                        .frame(height: 1)
                        .padding(.horizontal, 14)

                    bodyStack
                        .padding(14)
                }
                .background { fogGlassCardBackground }
                .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                        .strokeBorder(Self.darkHairline.opacity(reduceTransparency ? 1.0 : 0.85), lineWidth: 1)
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
                FogGlassToolbarPillButton(
                    systemName: "chevron.backward",
                    accessibilityLabel: "Back to intro",
                    iconPointSize: 17,
                    action: { onboarding.returnToInterstitial() }
                )
            }
            ToolbarItem(placement: .principal) {
                FogToolbarPrincipalWordmark(useMaterialBackdrop: false)
            }
            ToolbarItem(placement: .topBarTrailing) {
                FogGlassToolbarPillButton(
                    systemName: "magnifyingglass",
                    accessibilityLabel: "Focus topic search",
                    accessibilityHint: "Moves keyboard focus to the topic search field",
                    action: { isSearchFieldFocused = true }
                )
            }
        }
    }

    private var searchBand: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Self.darkMutedText)
            TextField("Search a topic, question, hobby, or curiosity", text: $searchText)
                .textFieldStyle(.plain)
                .font(AppFont.body)
                .foregroundStyle(Self.darkPrimaryText)
                .tint(Self.darkPrimaryText.opacity(0.85))
                .focused($isSearchFieldFocused)
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
                                .foregroundStyle(Self.darkPrimaryText)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Self.darkMutedText)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background {
                            rowChromeBackground
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: rowCorner, style: .continuous)
                                .strokeBorder(Self.darkHairline, lineWidth: 1)
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
        RoundedRectangle(cornerRadius: rowCorner, style: .continuous)
            .fill(Self.darkRowFill.opacity(reduceTransparency ? 1.0 : 0.94))
    }

    private var fogGlassCardBackground: some View {
        RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Self.darkCardFill.opacity(reduceTransparency ? 1.0 : 0.98),
                        Color(red: 0.09, green: 0.09, blue: 0.095).opacity(reduceTransparency ? 1.0 : 0.98)
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
