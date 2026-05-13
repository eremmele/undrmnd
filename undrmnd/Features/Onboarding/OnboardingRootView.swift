import SwiftUI

/// Single sheet identity so SwiftUI/Cursor type-checking does not choke on stacked `sheet(item:)` modifiers.
private enum FirstIslandSheet: Identifiable, Equatable {
    case article(contentId: UUID)
    case contribution(Strata)

    var id: String {
        switch self {
        case let .article(contentId):
            return "article-\(contentId.uuidString)"
        case let .contribution(strata):
            return "contribution-\(strata.id.uuidString)"
        }
    }
}

/// Linear first-run stack: interstitial → choose seed → island → read → contribute → handoff.
struct OnboardingRootView: View {
    @EnvironmentObject private var onboarding: OnboardingCoordinator
    @State private var firstIslandSheet: FirstIslandSheet?

    var body: some View {
        Group {
            switch onboarding.phase {
            case .interstitial:
                IntroInterstitialView {
                    onboarding.continuedFromInterstitial()
                }

            case .chooseBeginning:
                NavigationStack {
                    ChooseBeginningView()
                        .environmentObject(onboarding)
                }

            case .revealing:
                NavigationStack {
                    RevealingFogMapLoadingView()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                FogGlassToolbarPillButton(systemName: "chevron.backward", accessibilityLabel: "Back to topic search") {
                                    onboarding.returnToTopicSearchFromRevealing()
                                }
                            }
                            ToolbarItem(placement: .principal) {
                                FogToolbarPrincipalWordmark()
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                        .tint(RevealingFogChrome.mapInkSoft)
                }
                .task {
                    try? await Task.sleep(nanoseconds: 280_000_000)
                    await onboarding.completeRevealTransition()
                }

            case .firstIsland:
                NavigationStack {
                    ZStack(alignment: .bottom) {
                        LearningCommonsFogMapView(
                            explorePath: .firstIsland(
                                strata: onboarding.starterCluster,
                                wideRevealFromContribution: onboarding.expandedFogReveal
                            ),
                            onThreadTap: { contentItemId in
                                firstIslandSheet = .article(contentId: contentItemId)
                            }
                        )
                        .ignoresSafeArea(edges: .top)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .tint(RevealingFogChrome.mapInkSoft)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            FogGlassToolbarPillButton(systemName: "chevron.backward", accessibilityLabel: "Back to topic search") {
                                onboarding.returnToTopicSearchFromMap()
                            }
                        }
                        ToolbarItem(placement: .principal) {
                            FogToolbarPrincipalWordmark()
                        }
                        ToolbarItem(placement: .primaryAction) {
                            if let primary = onboarding.starterCluster.first(where: { $0.mapVisibility == .revealed }) {
                                FogGlassToolbarPillButton(systemName: "square.and.pencil", accessibilityLabel: "Leave a short note for the library") {
                                    firstIslandSheet = .contribution(primary)
                                }
                                .accessibilityHint("Opens a small contribution sheet for your first field note")
                            }
                        }
                    }
                }
                .sheet(item: $firstIslandSheet) { sheet in
                    switch sheet {
                    case let .article(contentId):
                        NavigationStack {
                            ArticleView(contentId: contentId)
                                .toolbarBackground(UndrmndPrototypeTheme.paper, for: .navigationBar)
                                .toolbarBackground(.visible, for: .navigationBar)
                                .toolbarColorScheme(.light, for: .navigationBar)
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button {
                                            firstIslandSheet = nil
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(UndrmndPrototypeTheme.primary)
                                        }
                                        .buttonStyle(.borderless)
                                        .accessibilityLabel("Close article")
                                    }
                                }
                        }
                    case let .contribution(strata):
                        OnboardingStrataDetailView(strata: strata) {
                            withAnimation(.easeOut(duration: 1.05)) {
                                onboarding.completeFirstContribution()
                            }
                        }
                        .presentationDetents([.fraction(0.48), .medium])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(20)
                        .presentationBackground(.ultraThinMaterial)
                    }
                }
                .onChange(of: onboarding.phase) { _, newPhase in
                    guard case .firstIsland = newPhase else {
                        firstIslandSheet = nil
                        return
                    }
                }

            case .onboardingComplete:
                Color.clear
            }
        }
    }
}

// MARK: - Reveal transition (dark fog chrome)

private enum RevealingFogChrome {
    static let nightFog = Color(red: 22 / 255, green: 20 / 255, blue: 15 / 255)
    static let mapInkSoft = Color(red: 233 / 255, green: 226 / 255, blue: 209 / 255)
    static let ringAccent = Color(red: 196 / 255, green: 178 / 255, blue: 138 / 255)
}

private struct RevealingFogMapLoadingView: View {
    var body: some View {
        ZStack {
            RevealingFogChrome.nightFog.ignoresSafeArea(edges: .top)

            VStack(spacing: 18) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(RevealingFogChrome.ringAccent)

                Text("Opening the map…")
                    .font(AppFont.body)
                    .foregroundStyle(RevealingFogChrome.mapInkSoft.opacity(0.88))
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Opening the map")
        }
    }
}

#Preview {
    OnboardingRootView()
        .environmentObject(OnboardingCoordinator())
}
