import SwiftUI

enum HomeRoute: Hashable {
    case goalClarifier
    case path(String)
    case threeCard(Pillar?)
    case articleForCard(UUID)
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
    @State private var contributePath = NavigationPath()
    @State private var showSearch = false
    @State private var showExploreMap = false
    @State private var showAlerts = false

    @StateObject private var alertsStore = AlertsStore()

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $explorePath) {
                ExploreFogRootView(
                    onGoalClarifier: { explorePath.append(HomeRoute.goalClarifier) },
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
                    case .articleForCard(let id):
                        ArticleView(contentId: id)
                    case .territoryMap:
                        TerritoryMapPlaceholderView { pillar in
                            explorePath.append(HomeRoute.threeCard(pillar))
                        }
                    case .about:
                        AboutUndrmndView()
                    }
                }
            }
            .environment(\.openArticleForContent) { id in
                explorePath.append(HomeRoute.articleForCard(id))
            }
            .appShellNavigationToolbar()
            .tabItem {
                Label("Explore", systemImage: "sparkles")
            }
            .tag(MainTab.explore)

            NavigationStack(path: $contributePath) {
                ContributeView()
                    .navigationDestination(for: UUID.self) { threadId in
                        ContributeThreadDetailLoader(threadId: threadId)
                    }
            }
            .appShellNavigationToolbar()
            .tabItem {
                Label("Contribute", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(MainTab.contribute)

            NavigationStack {
                NearbyEventsView()
            }
            .appShellNavigationToolbar()
            .tabItem {
                Label("Nearby", systemImage: "mappin.and.ellipse")
            }
            .tag(MainTab.nearby)

            NavigationStack {
                ProfileView()
            }
            .appShellNavigationToolbar()
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
            SearchPlaceholderView { pick in
                showSearch = false
                switch pick {
                case .home(let route):
                    tab = .explore
                    explorePath.append(route)
                case .communityThread(let id):
                    tab = .contribute
                    contributePath.append(id)
                }
            }
            .environmentObject(alertsStore)
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
            .appShellNavigationToolbar()
            .environmentObject(alertsStore)
        }
        .sheet(isPresented: $showAlerts) {
            AlertsPanelView()
                .environmentObject(alertsStore)
        }
    }
}

struct PrototypeEntryView: View {
    var onGoalClarifier: () -> Void
    var onPathSlug: (String) -> Void
    var onThreeCard: (Pillar?) -> Void
    var onTerritoryMap: () -> Void
    var onOpenMap: () -> Void
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

                Text("Explore")
                    .font(AppFont.title2)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)

                Text("Search topics, open paths, or pick up threads you’ve already started.")
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 14) {
                    compactRow(title: "Search topics & paths", subtitle: nil, action: onGoalClarifier)
                    compactRow(title: "Topic map", subtitle: "See how themes connect", action: onTerritoryMap)
                    compactRow(title: "Community", subtitle: "What others are building", action: onOpenContribute)
                    compactRow(title: "Resume", subtitle: "Continue a path", action: onOpenMap)
                    compactRow(title: "About undrmnd", subtitle: nil, action: onAbout)
                }
                .padding(.top, 20)
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
        }
    }

    private func compactRow(title: String, subtitle: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.subheadlineEmphasis)
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppFont.caption2)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 4)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(UndrmndPrototypeTheme.divider)
                    .frame(height: 0.5)
            }
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

private struct OpenArticleForContentKey: EnvironmentKey {
    static let defaultValue: (UUID) -> Void = { _ in }
}

private struct ReturnToIntroSplashKey: EnvironmentKey {
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

    /// Present the in-app **alerts** panel (local content, not remote push).
    var openAlertsFromShell: () -> Void {
        get { self[OpenAlertsKey.self] }
        set { self[OpenAlertsKey.self] = newValue }
    }

    /// Push the article (Open the work) for a `content_items` id on the current Explore stack.
    var openArticleForContent: (UUID) -> Void {
        get { self[OpenArticleForContentKey.self] }
        set { self[OpenArticleForContentKey.self] = newValue }
    }

    /// Dismiss main shell and show the scan intro again (wired from `UndrmndApp`).
    var returnToIntroSplash: () -> Void {
        get { self[ReturnToIntroSplashKey.self] }
        set { self[ReturnToIntroSplashKey.self] = newValue }
    }
}

/// Search + map + alerts dock. Applied **once** on each `NavigationStack` root (see `appShellNavigationToolbar()`), not on every pushed screen, so the chrome does not re-mount and flicker.
struct AppShellToolbarTrailing: View {
    @Environment(\.openTerritoryMapFromShell) private var openTerritoryMap
    @Environment(\.openTopicSearchFromShell) private var openTopicSearch
    @Environment(\.openAlertsFromShell) private var openAlertsFromShell
    @EnvironmentObject private var alerts: AlertsStore

    var body: some View {
        HStack(spacing: 8) {
            ToolbarPillButton(
                systemName: "magnifyingglass",
                accessibilityLabel: "Search topics and paths",
                action: openTopicSearch
            )
            ToolbarPillButton(
                systemName: "map",
                accessibilityLabel: "Open your topic map",
                action: openTerritoryMap
            )
            if alerts.unreadCount > 0 {
                Button(action: openAlertsFromShell) {
                    Image(systemName: "bell")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        .frame(width: 40, height: 40)
                        .background { ToolbarPillBackground() }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open alerts, \(alerts.unreadCount) unread")
                .badge(alerts.unreadCount)
            } else {
                ToolbarPillButton(
                    systemName: "bell",
                    accessibilityLabel: "Open alerts",
                    action: openAlertsFromShell
                )
            }
        }
    }
}

extension View {
    /// Fixed shell dock (search, map, alerts) for the given navigation stack. Attach to `NavigationStack`, not to individual destinations.
    func appShellNavigationToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                AppShellToolbarTrailing()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AlertsStore())
}
