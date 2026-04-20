import SwiftUI

enum HomeRoute: Hashable {
    case goalClarifier
    case walk(WalkPath)
    case territoryMap
}

private struct ClosingSheetPayload: Identifiable {
    let id = UUID()
    let path: WalkPath
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
    @State private var closingSheet: ClosingSheetPayload?

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $homePath) {
                PrototypeEntryView(
                    onSearch: { showSearch = true },
                    onProfile: { tab = .profile },
                    onGoalClarifier: { homePath.append(HomeRoute.goalClarifier) },
                    onFirstWalk: { homePath.append(HomeRoute.walk(.firstWalk)) },
                    onResume: { homePath.append(HomeRoute.walk(SavedPathProgress.demoResume.path)) },
                    onTerritoryMap: { homePath.append(HomeRoute.territoryMap) }
                )
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .goalClarifier:
                        GoalClarifierView {
                            homePath.append(HomeRoute.walk(.climateAnxiety))
                        }
                    case .walk(let path):
                        WalkPathFlowView(
                            path: path,
                            onDestinationAction: { action, _ in
                                handleDestination(action)
                            },
                            onClosing: { walk in
                                closingSheet = ClosingSheetPayload(path: walk)
                            }
                        )
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
                ProfilePlaceholderView()
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
        .sheet(item: $closingSheet) { payload in
            ClosingSessionSheet(path: payload.path) {
                closingSheet = nil
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func handleDestination(_ action: String) {
        switch action {
        case "campfire":
            tab = .campfire
        case "nearby", "event":
            tab = .nearby
        case "territory":
            tab = .home
            homePath.append(HomeRoute.territoryMap)
        case "entry":
            tab = .home
            homePath = NavigationPath()
        default:
            break
        }
    }
}

// MARK: - Entry (`UA` in the web bundle)

struct PrototypeEntryView: View {
    var onSearch: () -> Void
    var onProfile: () -> Void
    var onGoalClarifier: () -> Void
    var onFirstWalk: () -> Void
    var onResume: () -> Void
    var onTerritoryMap: () -> Void

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
                    subtitle: "Find a community, understand an issue, contribute to a thread",
                    action: onGoalClarifier
                )

                entryCard(
                    title: "Help me begin",
                    subtitle: "I'm not sure where to start — take me on a guided walk",
                    action: onFirstWalk
                )

                resumeCard

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
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("undrmnd")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .tracking(0.08)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button(action: onSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.subheadline)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    }
                    .accessibilityLabel("Search")

                    Button(action: onProfile) {
                        Image(systemName: "person.circle")
                            .font(.subheadline)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    }
                    .accessibilityLabel("Profile")
                }
            }
        }
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

    private var resumeCard: some View {
        let p = SavedPathProgress.demoResume
        return Button(action: onResume) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Resume my path")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                Text("\(p.title) — \(p.completedNodes) of \(p.totalNodes) nodes")
                    .font(.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(UndrmndPrototypeTheme.divider)
                        Rectangle()
                            .fill(UndrmndPrototypeTheme.primary)
                            .frame(width: geo.size.width * CGFloat(p.completedNodes) / CGFloat(max(p.totalNodes, 1)))
                    }
                }
                .frame(height: 3)
                .accessibilityLabel("Path progress \(p.completedNodes) of \(p.totalNodes)")
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
        .accessibilityHint("Continues your in-progress path")
    }
}

#Preview {
    RootView()
}
