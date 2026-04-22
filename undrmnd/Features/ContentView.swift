import SwiftUI

enum HomeRoute: Hashable {
    case goalClarifier
    case path(String)
    case threeCard(Pillar?)
    case territoryMap
    case about
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
    @State private var showAlerts = false

    @StateObject private var alertsStore = AlertsStore()

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $explorePath) {
                PrototypeEntryView(
                    onSearch: { showSearch = true },
                    onOpenMap: { showExploreMap = true },
                    onOpenAlerts: { showAlerts = true },
                    onGoalClarifier: { explorePath.append(HomeRoute.goalClarifier) },
                    onPathSlug: { slug in explorePath.append(HomeRoute.path(slug)) },
                    onThreeCard: { p in explorePath.append(HomeRoute.threeCard(p)) },
                    onTerritoryMap: { explorePath.append(HomeRoute.territoryMap) },
                    onOpenContribute: { tab = .contribute },
                    onAbout: { explorePath.append(HomeRoute.about) }
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
                    case .about:
                        AboutUndrmndView()
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
        .environmentObject(alertsStore)
        .environment(\.openTerritoryMapFromShell) { showExploreMap = true }
        .environment(\.openTopicSearchFromShell) { showSearch = true }
        .environment(\.openAlertsFromShell) { showAlerts = true }
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
        .sheet(isPresented: $showAlerts) {
            AlertsPanelView()
                .environmentObject(alertsStore)
        }
    }
}

struct PrototypeEntryView: View {
    @EnvironmentObject private var alertsStore: AlertsStore

    var onSearch: () -> Void
    var onOpenMap: () -> Void
    var onOpenAlerts: () -> Void
    var onGoalClarifier: () -> Void
    var onPathSlug: (String) -> Void
    var onThreeCard: (Pillar?) -> Void
    var onTerritoryMap: () -> Void
    var onOpenContribute: () -> Void
    var onAbout: () -> Void

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

                VStack(alignment: .leading, spacing: 18) {
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
                        action: onOpenMap
                    )

                    entryCard(
                        title: "Why undrmnd",
                        subtitle: "Short about cards: what this is, what it’s not, and how your attention is treated.",
                        action: onAbout
                    )
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("undrmnd")
                    .font(AppFont.brandWordmark)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    ToolbarPillButton(
                        systemName: "magnifyingglass",
                        accessibilityLabel: "Search",
                        action: onSearch
                    )
                    ToolbarPillButton(
                        systemName: "map",
                        accessibilityLabel: "Open your topic map",
                        action: onOpenMap
                    )
                    if alertsStore.unreadCount > 0 {
                        Button(action: onOpenAlerts) {
                            Image(systemName: "bell")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                                .frame(width: 40, height: 40)
                                .background { ToolbarPillBackground() }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open alerts, \(alertsStore.unreadCount) unread")
                        .badge(alertsStore.unreadCount)
                    } else {
                        ToolbarPillButton(
                            systemName: "bell",
                            accessibilityLabel: "Open alerts",
                            action: onOpenAlerts
                        )
                    }
                }
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

// MARK: - Toolbar chrome (separate rounded “docks” for each control)

private struct ToolbarPillBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(UndrmndPrototypeTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 0.5)
            )
    }
}

/// 40×40 rounded control; use in an `HStack(spacing: 8)` so search, map, and alerts read as separate docks.
struct ToolbarPillButton: View {
    let systemName: String
    var accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                .frame(width: 40, height: 40)
                .background { ToolbarPillBackground() }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Global Explore shell (map + search) for any pushed screen

private struct OpenTerritoryMapKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenTopicSearchKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct OpenAlertsKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    /// Present the territory map sheet (same as Explore toolbar map).
    var openTerritoryMapFromShell: () -> Void {
        get { self[OpenTerritoryMapKey.self] }
        set { self[OpenTerritoryMapKey.self] = newValue }
    }

    /// Present the topic / path search sheet (same as Explore toolbar search).
    var openTopicSearchFromShell: () -> Void {
        get { self[OpenTopicSearchKey.self] }
        set { self[OpenTopicSearchKey.self] = newValue }
    }

    /// Present the in-app **alerts** panel (on-device copy only; not remote push).
    var openAlertsFromShell: () -> Void {
        get { self[OpenAlertsKey.self] }
        set { self[OpenAlertsKey.self] = newValue }
    }
}

enum ExploreShellToolbar {
    @ToolbarContentBuilder
    static func items(
        openMap: @escaping () -> Void,
        openSearch: @escaping () -> Void,
        openAlerts: @escaping () -> Void = {}
    ) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            HStack(spacing: 8) {
                ToolbarPillButton(
                    systemName: "magnifyingglass",
                    accessibilityLabel: "Search topics and paths",
                    action: openSearch
                )
                ToolbarPillButton(
                    systemName: "map",
                    accessibilityLabel: "Open your topic map",
                    action: openMap
                )
                ToolbarPillButton(
                    systemName: "bell",
                    accessibilityLabel: "Open alerts",
                    action: openAlerts
                )
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AlertsStore())
}
