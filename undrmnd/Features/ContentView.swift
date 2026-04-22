import SwiftUI

enum HomeRoute: Hashable {
    case goalClarifier
    case path(String)
    case threeCard(Pillar?)
    case territoryMap
}

struct RootView: View {
    enum MainTab: Hashable {
        case explore
        case contribute
        case nearby
        case profile
    }

    @State private var tab: MainTab = .explore
    @State private var explorePath = NavigationPath()
    @State private var showSearch = false
    @State private var showExploreMap = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $explorePath) {
                PrototypeEntryView(
                    onSearch: { showSearch = true },
                    onOpenMap: { showExploreMap = true },
                    onGoalClarifier: { explorePath.append(HomeRoute.goalClarifier) },
                    onPathSlug: { slug in explorePath.append(HomeRoute.path(slug)) },
                    onThreeCard: { p in explorePath.append(HomeRoute.threeCard(p)) },
                    onTerritoryMap: { explorePath.append(HomeRoute.territoryMap) },
                    onOpenContribute: { tab = .contribute }
                )
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .goalClarifier:
                        GoalClarifierView(
                            onSelectPath: { slug in explorePath.append(HomeRoute.path(slug)) },
                            onThreeCardSession: { p in explorePath.append(HomeRoute.threeCard(p)) }
                        )
                    case .path(let slug):
                        PathView(slug: slug)
                    case .threeCard(let pillar):
                        ThreeCardSessionView(topicFilter: pillar)
                    case .territoryMap:
                        TerritoryMapPlaceholderView { pillar in
                            explorePath.append(HomeRoute.threeCard(pillar))
                        }
                    }
                }
            }
            .tabItem {
                Label("Explore", systemImage: "sparkles")
            }
            .tag(MainTab.explore)

            NavigationStack {
                ContributeView()
            }
            .tabItem {
                Label("Contribute", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(MainTab.contribute)

            NavigationStack {
                NearbyEventsView()
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
            SearchPlaceholderView { route in
                showSearch = false
                tab = .explore
                explorePath.append(route)
            }
        }
        .sheet(isPresented: $showExploreMap) {
            NavigationStack {
                TerritoryMapPlaceholderView(
                    onSelectPillar: { pillar in
                        showExploreMap = false
                        tab = .explore
                        explorePath.append(HomeRoute.threeCard(pillar))
                    },
                    onMapDismiss: { showExploreMap = false }
                )
            }
        }
    }
}

struct PrototypeEntryView: View {
    var onSearch: () -> Void
    var onOpenMap: () -> Void
    var onGoalClarifier: () -> Void
    var onPathSlug: (String) -> Void
    var onThreeCard: (Pillar?) -> Void
    var onTerritoryMap: () -> Void
    var onOpenContribute: () -> Void

    @State private var showNoResumeAlert = false

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 18 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(greeting)
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)

                Text("Where would you like to start?")
                    .font(AppFont.title2)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 10) {
                    entryCard(
                        title: "I want to know something",
                        subtitle: "Set your goal, ask questions, and find the answers you’re seeking.",
                        action: onGoalClarifier
                    )

                    entryCard(
                        title: "Explore the community",
                        subtitle: "See what your colleagues are researching.",
                        action: onOpenContribute
                    )

                    entryCard(
                        title: "Resume a path",
                        subtitle: "Continue where you left off in a previous exploration.",
                        action: {
                            if let slug = PathResumeStore.lastPathSlug {
                                onPathSlug(slug)
                            } else {
                                showNoResumeAlert = true
                            }
                        }
                    )
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .alert("No path in progress", isPresented: $showNoResumeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Open a path from a goal or search first — we’ll save it for next time.")
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("undrmnd")
                    .font(AppFont.brandWordmark)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: onOpenMap) {
                    Image(systemName: "map")
                        .font(.system(.subheadline))
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }
                .accessibilityLabel("Open your topic map")
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(.subheadline))
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }
                .accessibilityLabel("Search")
            }
        }
    }

    private func entryCard(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(AppFont.subheadlineEmphasis)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                Text(subtitle)
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(UndrmndPrototypeTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootView()
}
