import SwiftUI
import UIKit

enum HomeRoute: Hashable {
    case goalClarifier
    case path(String)
    case threeCard(Pillar?)
    case articleForCard(UUID)
    case territoryMap
    case about
}

extension HomeRoute {
    /// Routes that keep ``ShellChromeStyle/darkGlass`` tab + shell toolbar while the user stays on map-like surfaces (fog canvas or instrument map).
    var keepsExploreFogChrome: Bool {
        switch self {
        case .goalClarifier, .threeCard, .territoryMap:
            return true
        case .path, .articleForCard, .about:
            return false
        }
    }
}

/// Shell chrome for tab bar + Explore stack navigation (fog maps vs paper surfaces).
enum ShellChromeStyle: Hashable {
    case lightPaper
    case darkGlass
}

private struct ShellChromeStyleKey: EnvironmentKey {
    static let defaultValue: ShellChromeStyle = .lightPaper
}

extension EnvironmentValues {
    /// Current main-shell chrome; drives tab bar material and Explore navigation bar treatment.
    var shellChromeStyle: ShellChromeStyle {
        get { self[ShellChromeStyleKey.self] }
        set { self[ShellChromeStyleKey.self] = newValue }
    }
}

private struct ReplayIntroSplashActiveKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// True while the full-screen intro replay overlay is up (`UndrmndApp`); suppresses tab chrome underneath.
    var replayIntroSplashActive: Bool {
        get { self[ReplayIntroSplashActiveKey.self] }
        set { self[ReplayIntroSplashActiveKey.self] = newValue }
    }
}

/// Shared fog-map toolbar ink (warm paper-white on charcoal).
enum FogMapShellChrome {
    static let mapInkSoft = Color(red: 233 / 255, green: 226 / 255, blue: 209 / 255)
}

struct RootView: View {
    enum MainTab: Hashable {
        case explore
        case contribute
        case nearby
        case profile
    }

    @Environment(\.replayIntroSplashActive) private var replayIntroSplashActive
    @EnvironmentObject private var onboarding: OnboardingCoordinator
    @State private var tab: MainTab = .explore
    @State private var explorePath: [HomeRoute] = []
    @State private var contributePath = NavigationPath()
    @State private var showSearch = false
    @State private var showExploreMap = false
    @State private var showAlerts = false

    @StateObject private var alertsStore = AlertsStore()

    /// Bottom tabs stay hidden on the intro interstitial and while the intro replay overlay is up; visible on topic search (choose beginning), reveal/island onboarding, and the main app.
    private var showsMainTabBar: Bool {
        if replayIntroSplashActive { return false }
        if onboarding.hasUnlockedMainNavigation { return true }
        switch onboarding.phase {
        case .interstitial:
            return false
        case .chooseBeginning:
            return true
        case .revealing, .firstIsland, .onboardingComplete:
            return true
        }
    }

    /// Explore stack: dark floating chrome on fog roots and fog-backed routes; paper flows when reading paths/articles.
    private var exploreStackChromeStyle: ShellChromeStyle {
        if !onboarding.hasUnlockedMainNavigation {
            switch onboarding.phase {
            case .chooseBeginning, .revealing, .firstIsland:
                return .darkGlass
            default:
                return .lightPaper
            }
        }
        if explorePath.isEmpty || explorePath.last?.keepsExploreFogChrome == true {
            return .darkGlass
        }
        return .lightPaper
    }

    /// Tab bar + global env: light on non-Explore tabs; on Explore, match fog vs paper chrome from the current route.
    private var shellChromeStyleForCurrentTab: ShellChromeStyle {
        switch tab {
        case .explore:
            return exploreStackChromeStyle
        default:
            return .lightPaper
        }
    }

    /// Tab bar selection tint: dark ink so the selected tab stays readable on the system’s light selection capsule over fog.
    private var tabSelectionTint: Color {
        UndrmndPrototypeTheme.primary
    }

    @ViewBuilder
    private func exploreDestination(for route: HomeRoute) -> some View {
        switch route {
        case .goalClarifier:
            ZStack {
                LearningCommonsFogMapView(
                    explorePath: .curiosityEntry(typingRevealProgress: 0.32),
                    onThreadTap: nil
                )
                .ignoresSafeArea()
                GoalClarifierView(
                    onSelectPath: { slug in explorePath.append(.path(slug)) },
                    onThreeCardSession: { p in explorePath.append(.threeCard(p)) }
                )
            }
            .environment(\.exploreUsesFogBackdrop, true)
        case .path(let slug):
            PathView(slug: slug)
        case .threeCard(let pillar):
            ZStack {
                LearningCommonsFogMapView(
                    explorePath: .curiosityEntry(typingRevealProgress: 0.28),
                    onThreadTap: nil
                )
                .ignoresSafeArea()
                ThreeCardSessionView(topicFilter: pillar)
            }
            .environment(\.exploreUsesFogBackdrop, true)
        case .articleForCard(let id):
            ArticleView(contentId: id)
        case .territoryMap:
            TerritoryMapPlaceholderView { pillar in
                explorePath.append(.threeCard(pillar))
            }
        case .about:
            AboutUndrmndView()
        }
    }

    var body: some View {
        TabView(selection: $tab) {
            Group {
                if onboarding.hasUnlockedMainNavigation {
                    NavigationStack(path: $explorePath) {
                        ExploreFogRootView(
                            onGoalClarifier: { explorePath.append(.goalClarifier) },
                            onTerritoryMap: { explorePath.append(.territoryMap) },
                            onOpenContribute: { tab = .contribute },
                            onAbout: { explorePath.append(.about) }
                        )
                        .navigationDestination(for: HomeRoute.self) { route in
                            exploreDestination(for: route)
                        }
                    }
                    .environment(\.openArticleForContent) { id in
                        explorePath.append(.articleForCard(id))
                    }
                    .modifier(ShellNavigationBarModifier(style: exploreStackChromeStyle))
                    .appShellNavigationToolbar()
                } else {
                    OnboardingRootView()
                }
            }
            // Hiding on the Explore tab content is required for reliable tab suppression (see Apple “toolbar hidden for tabBar”).
            .toolbar(showsMainTabBar ? .automatic : .hidden, for: .tabBar)
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
        .tint(tabSelectionTint)
        .environment(\.shellChromeStyle, shellChromeStyleForCurrentTab)
        .toolbar(showsMainTabBar ? .automatic : .hidden, for: .tabBar)
        .modifier(ShellTabBarChromeModifier(isVisible: showsMainTabBar, style: shellChromeStyleForCurrentTab))
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
            .environment(\.shellChromeStyle, .lightPaper)
        }
        .sheet(isPresented: $showExploreMap) {
            NavigationStack {
                TerritoryMapPlaceholderView(
                    onSelectPillar: { pillar in
                        showExploreMap = false
                        tab = .explore
                        explorePath.append(.threeCard(pillar))
                    },
                    onMapDismiss: { showExploreMap = false }
                )
            }
            .appShellNavigationToolbar()
            .environmentObject(alertsStore)
            .environment(\.shellChromeStyle, .lightPaper)
        }
        .sheet(isPresented: $showAlerts) {
            AlertsPanelView()
                .environmentObject(alertsStore)
                .environment(\.shellChromeStyle, .lightPaper)
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

/// Fog navigation / trailing dock: **icon only** (no custom disk). iOS 26 supplies a single liquid container; drawing our own disk stacked a second “squircle”.
struct FogGlassToolbarPillButton: View {
    let systemName: String
    var accessibilityLabel: String
    var accessibilityHint: String?
    /// `chevron.backward` reads clearer at ~17pt.
    var iconPointSize: CGFloat = 16
    let action: () -> Void

    private var buttonCore: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconPointSize, weight: .semibold))
                .foregroundStyle(FogMapShellChrome.mapInkSoft.opacity(0.96))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    var body: some View {
        if let accessibilityHint, !accessibilityHint.isEmpty {
            buttonCore.accessibilityHint(accessibilityHint)
        } else {
            buttonCore
        }
    }
}

/// Centered **undrmnd** for fog-map navigation; optional frosted capsule (Explore / first island) vs plain text (topic search).
struct FogToolbarPrincipalWordmark: View {
    var useMaterialBackdrop: Bool = true

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Text("undrmnd")
            .font(AppFont.brandWordmark)
            .foregroundStyle(FogMapShellChrome.mapInkSoft.opacity(0.96))
            .padding(.horizontal, useMaterialBackdrop ? 16 : 0)
            .padding(.vertical, useMaterialBackdrop ? 7 : 0)
            .background {
                if useMaterialBackdrop {
                    Group {
                        if reduceTransparency {
                            Capsule().fill(Color.black.opacity(0.52))
                        } else {
                            Capsule().fill(.ultraThinMaterial)
                        }
                    }
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
                    )
                }
            }
            .accessibilityLabel("undrmnd")
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

private enum UndrmndUITabBarSync {
    /// Aligns UIKit tab bar with SwiftUI fog chrome (removes the extra gray slab under the floating items).
    static func apply(tabBarVisible: Bool, style: ShellChromeStyle) {
        let appearance = UITabBarAppearance()
        if !tabBarVisible {
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
        } else if style == .darkGlass {
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            appearance.shadowImage = UIImage()
            appearance.shadowColor = nil
            // Unselected: soft cream on the fog. Selected: dark ink so labels/icons stay legible on the system’s light “liquid” selection pill (iOS 18+).
            let normalOnFog = UIColor(red: 233 / 255, green: 226 / 255, blue: 209 / 255, alpha: 0.52)
            let selectedOnSystemPill = UIColor(red: 0.1, green: 0.1, blue: 0.099, alpha: 1.0)
            appearance.stackedLayoutAppearance.normal.iconColor = normalOnFog
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalOnFog]
            appearance.stackedLayoutAppearance.selected.iconColor = selectedOnSystemPill
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedOnSystemPill]
            appearance.inlineLayoutAppearance.normal.iconColor = normalOnFog
            appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalOnFog]
            appearance.inlineLayoutAppearance.selected.iconColor = selectedOnSystemPill
            appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedOnSystemPill]
            appearance.compactInlineLayoutAppearance.normal.iconColor = normalOnFog
            appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalOnFog]
            appearance.compactInlineLayoutAppearance.selected.iconColor = selectedOnSystemPill
            appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedOnSystemPill]
        } else {
            // lightPaper: keep ink tokens for items, but **no** full-width paper slab — fog / scroll content shows through.
            // Opaque `paper` + `isTranslucent == false` also fights iOS 26’s floating tab bar (extra lift + solid white under the pill).
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.backgroundEffect = nil
            appearance.shadowImage = UIImage()
            appearance.shadowColor = nil
            let secondary = UIColor(red: 0.29, green: 0.283, blue: 0.275, alpha: 1.0)
            let primary = UIColor(red: 0.1, green: 0.1, blue: 0.098, alpha: 1.0)
            appearance.stackedLayoutAppearance.normal.iconColor = secondary
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: secondary]
            appearance.stackedLayoutAppearance.selected.iconColor = primary
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: primary]
            appearance.inlineLayoutAppearance.normal.iconColor = secondary
            appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: secondary]
            appearance.inlineLayoutAppearance.selected.iconColor = primary
            appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: primary]
            appearance.compactInlineLayoutAppearance.normal.iconColor = secondary
            appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: secondary]
            appearance.compactInlineLayoutAppearance.selected.iconColor = primary
            appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: primary]
        }
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        // Liquid-glass / floating tab bars expect translucency when visible; forcing false pins an opaque strip and lifts the bar on newer OS versions.
        tabBar.isTranslucent = tabBarVisible
        if style == .darkGlass, tabBarVisible {
            tabBar.tintColor = UIColor(red: 0.1, green: 0.1, blue: 0.099, alpha: 1.0)
        } else {
            tabBar.tintColor = nil
        }
    }
}

private struct ShellTabBarChromeModifier: ViewModifier {
    let isVisible: Bool
    let style: ShellChromeStyle

    func body(content: Content) -> some View {
        Group {
            if !isVisible {
                content
            } else {
                switch style {
                case .lightPaper:
                    content
                        .toolbarBackground(.hidden, for: .tabBar)
                        .toolbarColorScheme(.light, for: .tabBar)
                case .darkGlass:
                    content
                        .toolbarBackground(.hidden, for: .tabBar)
                        .toolbarColorScheme(.dark, for: .tabBar)
                }
            }
        }
        .onAppear {
            UndrmndUITabBarSync.apply(tabBarVisible: isVisible, style: isVisible ? style : .lightPaper)
        }
        .onChange(of: isVisible) { _, newVisible in
            UndrmndUITabBarSync.apply(tabBarVisible: newVisible, style: newVisible ? style : .lightPaper)
        }
        .onChange(of: style) { _, newStyle in
            UndrmndUITabBarSync.apply(tabBarVisible: isVisible, style: isVisible ? newStyle : .lightPaper)
        }
    }
}

/// Explore `NavigationStack` only: floating fog chrome at root; paper when pushed screens apply `navigationTitleBrand`.
private struct ShellNavigationBarModifier: ViewModifier {
    let style: ShellChromeStyle

    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .lightPaper:
            content
                .toolbarBackground(UndrmndPrototypeTheme.paper, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.light, for: .navigationBar)
        case .darkGlass:
            content
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

/// Search + map + alerts dock. Applied **once** on each `NavigationStack` root (see `appShellNavigationToolbar()`), not on every pushed screen, so the chrome does not re-mount and flicker.
struct AppShellToolbarTrailing: View {
    @Environment(\.openTerritoryMapFromShell) private var openTerritoryMap
    @Environment(\.openTopicSearchFromShell) private var openTopicSearch
    @Environment(\.openAlertsFromShell) private var openAlertsFromShell
    @Environment(\.shellChromeStyle) private var shellChromeStyle
    @EnvironmentObject private var alerts: AlertsStore

    var body: some View {
        HStack(spacing: 8) {
            if shellChromeStyle == .darkGlass {
                FogGlassToolbarPillButton(
                    systemName: "magnifyingglass",
                    accessibilityLabel: "Search topics and paths",
                    action: openTopicSearch
                )
                FogGlassToolbarPillButton(
                    systemName: "map",
                    accessibilityLabel: "Open your topic map",
                    action: openTerritoryMap
                )
                if alerts.unreadCount > 0 {
                    fogBellBadgeButton
                } else {
                    FogGlassToolbarPillButton(
                        systemName: "bell",
                        accessibilityLabel: "Open alerts",
                        action: openAlertsFromShell
                    )
                }
            } else {
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

    private var fogBellBadgeButton: some View {
        Button(action: openAlertsFromShell) {
            Image(systemName: "bell")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(FogMapShellChrome.mapInkSoft.opacity(0.96))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open alerts, \(alerts.unreadCount) unread")
        .badge(alerts.unreadCount)
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
        .environmentObject(OnboardingCoordinator())
}
