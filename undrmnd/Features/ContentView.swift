import SwiftUI

enum HomeRoute: Hashable {
    case goalClarifier
    case path(String)
    case threeCard(Pillar?)
    case territoryMap
}

struct RootView: View {
    enum MainTab: Hashable {
        case home
        case campfire
        case nearby
        case profile
    }

    @State private var tab: MainTab = .home
    @State private var homePath = NavigationPath()
    @State private var showSearch = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $homePath) {
                PrototypeEntryView(
                    onSearch: { showSearch = true },
                    onGoalClarifier: { homePath.append(HomeRoute.goalClarifier) },
                    onPathSlug: { slug in homePath.append(HomeRoute.path(slug)) },
                    onThreeCard: { p in homePath.append(HomeRoute.threeCard(p)) },
                    onTerritoryMap: { homePath.append(HomeRoute.territoryMap) }
                )
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .goalClarifier:
                        GoalClarifierView(
                            onSelectPath: { slug in homePath.append(HomeRoute.path(slug)) },
                            onThreeCardSession: { p in homePath.append(HomeRoute.threeCard(p)) }
                        )
                    case .path(let slug):
                        PathView(slug: slug)
                    case .threeCard(let pillar):
                        ThreeCardSessionView(topicFilter: pillar)
                    case .territoryMap:
                        TerritoryMapPlaceholderView()
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "sparkles")
            }
            .tag(MainTab.home)

            NavigationStack {
                CampfirePlaceholderView()
            }
            .tabItem {
                Label("Campfire", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(MainTab.campfire)

            NavigationStack {
                NearbyPlaceholderView()
            }
            .tabItem {
                Label("Nearby", systemImage: "mappin.and.ellipse")
            }
            .tag(MainTab.nearby)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(MainTab.profile)
        }
        .tint(UndrmndPrototypeTheme.primary)
        .sheet(isPresented: $showSearch) {
            SearchPlaceholderView()
        }
    }
}

struct PrototypeEntryView: View {
    var onSearch: () -> Void
    var onGoalClarifier: () -> Void
    var onPathSlug: (String) -> Void
    var onThreeCard: (Pillar?) -> Void
    var onTerritoryMap: () -> Void

    @State private var featured: [PathRecord] = []
    @State private var loadError: String?

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 18 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(greeting)
                    .font(.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)

                Text("What brings you here today?")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .fixedSize(horizontal: false, vertical: true)

                entryCard(
                    title: "I have a goal",
                    subtitle: "Find a community, understand an issue, or pick a path that’s already live",
                    action: onGoalClarifier
                )

                entryCard(
                    title: "Your first exploration",
                    subtitle: "A short, gentle path to try (when `first-exploration` is live in the project)",
                    action: { onPathSlug("first-exploration") }
                )

                threeCardCTA

                if !featured.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Featured paths")
                            .font(.subheadline.weight(.semibold))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(featured) { p in
                                    featuredTile(p)
                                }
                            }
                        }
                    }
                } else {
                    Text("Paths coming soon")
                        .font(.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }

                if let loadError {
                    Text(loadError)
                        .font(.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }

                Button(action: onTerritoryMap) {
                    HStack(spacing: 6) {
                        Image(systemName: "map")
                            .font(.caption)
                        Text("See my map")
                            .font(.caption)
                    }
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Open your territory map")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadFeatured() }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("undrmnd")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .tracking(0.08)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }
                .accessibilityLabel("Search")
            }
        }
    }

    private var threeCardCTA: some View {
        Button {
            onThreeCard(nil)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("Three open questions, then a full stop")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                Text("A short, finite set — no “one more” here.")
                    .font(.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(UndrmndPrototypeTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func featuredTile(_ p: PathRecord) -> some View {
        Button {
            onPathSlug(p.slug)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                if let s = p.subtitle, !s.isEmpty {
                    Text(s)
                        .font(.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        .lineLimit(2)
                }
                Text(p.title)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.leading)
            }
            .frame(width: 200, alignment: .leading)
            .padding(12)
            .background(UndrmndPrototypeTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func entryCard(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(UndrmndPrototypeTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func loadFeatured() async {
        do {
            featured = try await PathService.fetchFeaturedPaths(limit: 10)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    RootView()
}
