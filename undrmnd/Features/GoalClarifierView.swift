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

    @Environment(\.exploreUsesFogBackdrop) private var exploreUsesFogBackdrop
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

    private var goalEyebrow: Color {
        exploreUsesFogBackdrop ? ExploreFogNavigationInk.muted : UndrmndPrototypeTheme.muted
    }

    private var goalSectionHeading: Color {
        exploreUsesFogBackdrop ? ExploreFogNavigationInk.title : UndrmndPrototypeTheme.primary
    }

    private var goalSupporting: Color {
        exploreUsesFogBackdrop ? ExploreFogNavigationInk.secondary : UndrmndPrototypeTheme.secondary
    }

    private var goalScrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("What are you curious about right now?")
                        .font(AppFont.title2)
                        .foregroundStyle(goalSectionHeading)
                    Text(
                        "You don’t need a polished question right now. Try a fragment or a full sentence to search open topics, or contribute one of your own."
                    )
                    .font(AppFont.subheadline)
                    .foregroundStyle(goalSupporting)
                    .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Search topics & paths")
                        .font(AppFont.caption)
                        .foregroundStyle(goalEyebrow)
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(goalEyebrow)
                        TextField("Try “dark matter”, “species”, “replication”…", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(AppFont.body)
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.search)
                            .keyboardType(.default)
                    }
                    .padding(16)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                            .allowsHitTesting(false)
                    )
                }

                if !trimmedQuery.isEmpty {
                    if searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No direct matches")
                                .font(AppFont.subheadlineEmphasis)
                                .foregroundStyle(UndrmndPrototypeTheme.primary)
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
                            .foregroundStyle(goalSectionHeading)
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
                        .foregroundStyle(goalSupporting)
                }

                if let loadError {
                    Text(loadError)
                        .font(AppFont.caption)
                        .foregroundStyle(goalSupporting)
                }
            }
            .padding(24)
            .padding(.bottom, 32)
        }
    }

    var body: some View {
        Group {
            if exploreUsesFogBackdrop {
                goalScrollContent
                    .background(Color.clear)
                    .navigationTitleBrandFog("Your goal")
            } else {
                goalScrollContent
                    .background(UndrmndPrototypeTheme.paper)
                    .navigationTitleBrand("Your goal")
            }
        }
        .task { await load() }
    }

    private var suggestedBrowseSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent topics")
                .font(AppFont.subheadlineEmphasis)
                .foregroundStyle(goalSectionHeading)
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
