import SwiftUI

/// Explore tab home: fog map + Strata cluster backed by real `content_items` ids (same contract as onboarding island).
struct ExploreFogRootView: View {
    var onGoalClarifier: () -> Void
    var onTerritoryMap: () -> Void
    var onOpenContribute: () -> Void
    var onAbout: () -> Void

    @Environment(\.openArticleForContent) private var openArticleForContent
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var strata: [Strata] = []
    @State private var loadFailed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            LearningCommonsFogMapView(
                explorePath: .firstIsland(strata: strata, wideRevealFromContribution: false),
                onThreadTap: { id in openArticleForContent(id) }
            )
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: 6) {
                Text("Clear the fog, then tap a lit dot to open a contributed card.")
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if loadFailed {
                    Text("Couldn’t load the live map cluster; try again from search or Contribute.")
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .allowsHitTesting(false)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Menu {
                        Button("Set a goal and find a path", action: onGoalClarifier)
                        Button("Topic map", action: onTerritoryMap)
                        Button("Community threads", action: onOpenContribute)
                        Button("About undrmnd", action: onAbout)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(FogMapShellChrome.mapInkSoft.opacity(0.92))
                            .padding(14)
                            .background {
                                if reduceTransparency {
                                    Circle().fill(Color.black.opacity(0.45))
                                } else {
                                    Circle().fill(.ultraThinMaterial)
                                }
                            }
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
                            )
                    }
                    .accessibilityLabel("More explore actions")
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(Color.clear)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                FogToolbarPrincipalWordmark()
            }
        }
        .task { await loadStrata() }
    }

    private func loadStrata() async {
        loadFailed = false
        do {
            let previews = try await ContentService.fetchRandomCards(n: 8, padWithSessionFallback: false)
            let cluster = Strata.mapCluster(from: previews)
            await MainActor.run {
                strata = cluster
            }
        } catch {
            await MainActor.run {
                strata = []
                loadFailed = true
            }
        }
    }
}
