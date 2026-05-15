import SwiftUI

/// Thumb-first fog entry: drifting fog fills the screen; unified topic search in the lower third.
struct ChooseBeginningView: View {
    @EnvironmentObject private var onboarding: OnboardingCoordinator
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
    /// Frozen while the search field is focused so the fog map does not re-layout every keystroke.
    @State private var fogRevealProgress: CGFloat = 0
    @State private var fogRevealFrozen: CGFloat = 0

    private let cardCorner: CGFloat = 22

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            LearningCommonsFogMapView(
                explorePath: .curiosityEntry(typingRevealProgress: fogRevealProgress),
                onThreadTap: nil,
                pauseAnimation: isSearchFieldFocused,
                enablePointerReveal: !isSearchFieldFocused
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                    .allowsHitTesting(false)

                TopicSearchView(
                    chrome: .exploreFogCard,
                    onPick: { pick, seed in
                        handleSearchPick(pick, seed: seed)
                    },
                    query: $searchText,
                    searchFieldFocus: $isSearchFieldFocused,
                    autoFocusOnAppear: false,
                    scrollIndicators: .hidden,
                    contentPadding: 14
                )
                .frame(maxHeight: 420)
                .background { fogGlassCardBackground }
                .clipShape(RoundedRectangle(cornerRadius: cardCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
                        .strokeBorder(Color.white.opacity(reduceTransparency ? 0.10 : 0.085), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.14), radius: 28, y: 16)
                .padding(.horizontal, 24)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
            }
            .colorScheme(.dark)
        }
        .background(Color.clear)
        .onChange(of: searchText) { _, newValue in
            guard !isSearchFieldFocused else { return }
            let count = CGFloat(newValue.trimmingCharacters(in: .whitespacesAndNewlines).count)
            fogRevealProgress = min(1, count / 26)
        }
        .onChange(of: isSearchFieldFocused) { _, focused in
            if focused {
                fogRevealFrozen = min(1, CGFloat(trimmedQuery.count) / 26)
                fogRevealProgress = fogRevealFrozen
            } else {
                let count = CGFloat(trimmedQuery.count) / 26
                fogRevealProgress = min(1, count)
            }
        }
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

    private var fogGlassCardBackground: some View {
        RoundedRectangle(cornerRadius: cardCorner, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.13).opacity(reduceTransparency ? 1.0 : 0.98),
                        Color(red: 0.09, green: 0.09, blue: 0.095).opacity(reduceTransparency ? 1.0 : 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private func handleSearchPick(_ pick: GlobalSearchPick, seed: String?) {
        let label = seed ?? trimmedQuery
        guard !label.isEmpty else { return }
        onboarding.submitSeed(label)
    }
}

#Preview {
    NavigationStack {
        ChooseBeginningView()
            .environmentObject(OnboardingCoordinator())
    }
}
