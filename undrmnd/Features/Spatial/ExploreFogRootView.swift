import SwiftUI

/// Explore tab home: fog map + Strata cluster backed by real `content_items` ids (same contract as onboarding island).
struct ExploreFogRootView: View {
    var onGoalClarifier: () -> Void
    var onTerritoryMap: () -> Void
    var onOpenContribute: () -> Void
    var onAbout: () -> Void

    @Environment(\.openArticleForContent) private var openArticleForContent

    @State private var strata: [Strata] = []
    @State private var loadFailed = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            LearningCommonsFogMapView(
                explorePath: .firstIsland(strata: strata, wideRevealFromContribution: false),
                onThreadTap: { id in openArticleForContent(id) }
            )
            .ignoresSafeArea(edges: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                Text("Explore")
                    .font(AppFont.title3)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
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
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                            .padding(14)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("More explore actions")
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("undrmnd")
                    .font(AppFont.brandWordmark)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
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
