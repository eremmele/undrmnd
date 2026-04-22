import SwiftUI

// MARK: - Staged search (pillars, paths, keyword hints)

private enum StagedTopicCatalog {
    static func keywords(for p: Pillar) -> String {
        switch p {
        case .cosmos:
            return "cosmos space universe astronomy stars galaxy planets dark matter hubble james webb"
        case .livingWorld:
            return "life species nature ecology evolution forest ocean climate microbes biodiversity plants animals"
        case .mindAndBrain:
            return "mind brain attention psychology learning neuroscience sleep consciousness habits phones behavior"
        case .howWeKnow:
            return "method science evidence replication statistics classroom teaching knowledge measurement citizen"
        }
    }

}

private enum GoalSearchRow: Identifiable {
    case path(PathRecord)
    case pillar(Pillar)

    var id: String {
        switch self {
        case .path(let p): return "path-\(p.id.uuidString)"
        case .pillar(let p): return "pillar-\(p.rawValue)"
        }
    }
}

/// Open goal flow: staged search across pillars and live paths, plus quick three-card entry points.
struct GoalClarifierView: View {
    var onSelectPath: (String) -> Void
    var onThreeCardSession: (Pillar?) -> Void

    @Environment(\.openTerritoryMapFromShell) private var openTerritoryMap
    @Environment(\.openTopicSearchFromShell) private var openTopicSearch
    @Environment(\.openAlertsFromShell) private var openAlertsFromShell

    @State private var activePaths: [PathRecord] = []
    @State private var loadError: String?
    @State private var searchText: String = ""

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchResults: [GoalSearchRow] {
        let q = trimmedQuery
        if q.isEmpty { return [] }

        var rows: [GoalSearchRow] = []

        for p in activePaths {
            let hay = "\(p.title) \(p.subtitle ?? "")"
            if hay.localizedCaseInsensitiveContains(q) {
                rows.append(.path(p))
            }
        }

        for p in Pillar.allCases {
            let label = p.displayName
            let blob = "\(label) \(StagedTopicCatalog.keywords(for: p))"
            if blob.localizedCaseInsensitiveContains(q) {
                rows.append(.pillar(p))
            }
        }

        return rows
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What are you curious about right now?")
                        .font(AppFont.title2)
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                    Text(
                        "You don’t need a polished question. Type a word, a hunch, or a full sentence — we’ll surface paths, pillars, and short open-question runs that sit close to what you typed."
                    )
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Search topics & paths")
                        .font(AppFont.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        TextField("Try “dark matter”, “species”, “replication”…", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(AppFont.body)
                            .autocorrectionDisabled()
                    }
                    .padding(16)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                    )
                }

                if !trimmedQuery.isEmpty {
                    if searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No direct matches")
                                .font(AppFont.subheadlineEmphasis)
                            Text("Try a shorter word, a pillar name (Cosmos, Living World…), or clear the field to browse suggestions below.")
                                .font(AppFont.caption)
                                .foregroundStyle(UndrmndPrototypeTheme.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(UndrmndPrototypeTheme.paper)
                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(searchResults) { row in
                                searchResultButton(row)
                                if row.id != searchResults.last?.id {
                                    Divider()
                                        .background(UndrmndPrototypeTheme.divider)
                                }
                            }
                        }
                        .background(UndrmndPrototypeTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                        )
                    }
                } else {
                    suggestedBrowseSection
                }

                if !activePaths.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Paths from the library")
                            .font(AppFont.subheadlineEmphasis)
                        ForEach(activePaths, id: \.id) { p in
                            Button {
                                onSelectPath(p.slug)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let s = p.subtitle, !s.isEmpty {
                                        Text(s)
                                            .font(AppFont.caption)
                                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                                    }
                                    Text(p.title)
                                        .font(AppFont.subheadlineEmphasis)
                                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(UndrmndPrototypeTheme.panel)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    Text("No full paths are published right now. You can still use search above or pick an open-topic set by pillar.")
                        .font(AppFont.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Or: open topics, by pillar")
                        .font(AppFont.subheadlineEmphasis)
                    ForEach(Pillar.allCases) { pillar in
                        Button {
                            onThreeCardSession(pillar)
                        } label: {
                            Text("Explore \(pillar.displayName) — three cards, then stop")
                                .font(AppFont.caption)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .background(UndrmndPrototypeTheme.panel)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                        )
                    }
                    Button {
                        onThreeCardSession(nil)
                    } label: {
                        Text("No pillar filter — three cards, then stop")
                            .font(AppFont.caption)
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                }

                if let loadError {
                    Text(loadError)
                        .font(AppFont.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }
            }
            .padding(24)
            .padding(.bottom, 32)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand("Your goal")
        .toolbar {
            ExploreShellToolbar.items(openMap: openTerritoryMap, openSearch: openTopicSearch, openAlerts: openAlertsFromShell)
        }
        .task { await load() }
    }

    private var suggestedBrowseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Try a few staged topics")
                .font(AppFont.subheadlineEmphasis)
            Text("These match the v2 open-question set — tap to run three short cards in that pillar.")
                .font(AppFont.caption)
                .foregroundStyle(UndrmndPrototypeTheme.muted)
            let chips: [(String, Pillar)] = [
                ("Dark matter & cosmology", .cosmos),
                ("Speed of the universe (Hubble tension)", .cosmos),
                ("How many species on Earth?", .livingWorld),
                ("Plants, fungi, and “wood-wide” claims", .livingWorld),
                ("Why phones are hard to put down", .mindAndBrain),
                ("Replication in psychology", .howWeKnow)
            ]
            VStack(alignment: .leading, spacing: 10) {
                ForEach(chips, id: \.0) { label, pillar in
                    Button {
                        onThreeCardSession(pillar)
                    } label: {
                        HStack {
                            Text(label)
                                .font(AppFont.subheadline)
                                .foregroundStyle(UndrmndPrototypeTheme.primary)
                            Spacer()
                            Text(pillar.displayName)
                                .font(AppFont.caption2)
                                .foregroundStyle(UndrmndPrototypeTheme.muted)
                        }
                        .padding(12)
                        .background(UndrmndPrototypeTheme.paper)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func searchResultButton(_ row: GoalSearchRow) -> some View {
        switch row {
        case .path(let p):
            Button {
                onSelectPath(p.slug)
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Path")
                            .font(AppFont.caption2)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        Text(p.title)
                            .font(AppFont.subheadlineEmphasis)
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                        if let s = p.subtitle, !s.isEmpty {
                            Text(s)
                                .font(AppFont.caption)
                                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppFont.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
        case .pillar(let p):
            Button {
                onThreeCardSession(p)
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pillar")
                            .font(AppFont.caption2)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        Text(p.displayName)
                            .font(AppFont.subheadlineEmphasis)
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                        Text("Open topics, then a full stop")
                            .font(AppFont.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(AppFont.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                .padding(14)
            }
            .buttonStyle(.plain)
        }
    }

    private func load() async {
        do {
            activePaths = try await PathService.fetchActivePaths()
        } catch {
            loadError = "Couldn’t list paths. \(error.localizedDescription)"
        }
    }
}
