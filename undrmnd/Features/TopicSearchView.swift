import SwiftUI

// MARK: - Chrome (toolbar sheet = light paper; Explore / onboarding = fog ink)

enum TopicSearchChrome: Hashable {
    /// Global shell search sheet (`SearchPlaceholderView`).
    case lightPaper
    /// Explore fog stack (goal clarifier, full-bleed over map).
    case exploreFog
    /// Onboarding topic card on the fog map (charcoal command-palette tiles).
    case exploreFogCard
}

struct TopicSearchPalette {
    let canvas: Color
    let fieldPanel: Color
    let resultsPanel: Color
    let emptyStatePanel: Color
    let primary: Color
    let secondary: Color
    let muted: Color
    let divider: Color
    let presetRowDivider: Color
    let usesFogFieldInk: Bool

    static func palette(for chrome: TopicSearchChrome) -> TopicSearchPalette {
        switch chrome {
        case .lightPaper:
            return TopicSearchPalette(
                canvas: UndrmndPrototypeTheme.paper,
                fieldPanel: UndrmndPrototypeTheme.panel,
                resultsPanel: UndrmndPrototypeTheme.panel,
                emptyStatePanel: UndrmndPrototypeTheme.paper,
                primary: UndrmndPrototypeTheme.primary,
                secondary: UndrmndPrototypeTheme.secondary,
                muted: UndrmndPrototypeTheme.muted,
                divider: UndrmndPrototypeTheme.divider,
                presetRowDivider: UndrmndPrototypeTheme.divider,
                usesFogFieldInk: false
            )
        case .exploreFog:
            return TopicSearchPalette(
                canvas: .clear,
                fieldPanel: Color(red: 0.17, green: 0.17, blue: 0.18),
                resultsPanel: Color(red: 0.17, green: 0.17, blue: 0.18),
                emptyStatePanel: Color(red: 0.12, green: 0.12, blue: 0.13),
                primary: ExploreFogNavigationInk.title,
                secondary: ExploreFogNavigationInk.secondary,
                muted: ExploreFogNavigationInk.muted,
                divider: Color.white.opacity(0.10),
                presetRowDivider: Color.white.opacity(0.10),
                usesFogFieldInk: true
            )
        case .exploreFogCard:
            return TopicSearchPalette(
                canvas: .clear,
                fieldPanel: Color(red: 0.17, green: 0.17, blue: 0.18),
                resultsPanel: Color(red: 0.17, green: 0.17, blue: 0.18),
                emptyStatePanel: Color(red: 0.12, green: 0.12, blue: 0.13),
                primary: Color(red: 0.93, green: 0.91, blue: 0.87),
                secondary: Color(red: 0.78, green: 0.76, blue: 0.72),
                muted: Color(red: 0.62, green: 0.60, blue: 0.56),
                divider: Color.white.opacity(0.10),
                presetRowDivider: Color.white.opacity(0.10),
                usesFogFieldInk: true
            )
        }
    }
}

/// Shared topic / library / thread search (semantic rank + presets). Light chrome for the shell sheet; fog chrome on Explore.
struct TopicSearchView: View {
    let chrome: TopicSearchChrome
    var onPick: (GlobalSearchPick, String?) -> Void
    /// When set, syncs query text (e.g. fog reveal on ``ChooseBeginningView``).
    var query: Binding<String>?
    /// When nil, focus is managed inside this view (shell search sheet).
    var searchFieldFocus: FocusState<Bool>.Binding?
    var autoFocusOnAppear: Bool = true
    var scrollIndicators: ScrollIndicatorVisibility = .automatic
    var contentPadding: CGFloat = 16

    @FocusState private var internalSearchFocus: Bool
    @State private var internalQuery: String = ""
    @State private var scoredContent: [ScoredContentHit] = []
    @State private var scoredThreads: [ScoredThreadHit] = []
    @State private var searchError: String?
    @State private var isQuerying = false
    @State private var embeddingDiagnostic: String?

    private struct ScoredContentHit: Identifiable {
        let item: ContentItem
        let score: Double
        var id: UUID { item.id }
    }

    private struct ScoredThreadHit: Identifiable {
        let row: ContributeThreadListRow
        let score: Double
        var id: UUID { row.id }
    }

    private let presets: [(String, HomeRoute)] = [
        ("Cosmos", .threeCard(.cosmos)),
        ("Living World", .threeCard(.livingWorld)),
        ("Mind & Brain", .threeCard(.mindAndBrain)),
        ("How We Know", .threeCard(.howWeKnow)),
        ("Set a goal and find a path", .goalClarifier)
    ]

    private var palette: TopicSearchPalette {
        TopicSearchPalette.palette(for: chrome)
    }

    private var searchQuery: Binding<String> {
        query ?? $internalQuery
    }

    private var filteredPresets: [(String, HomeRoute)] {
        let t = searchQuery.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return presets }
        return presets.filter { $0.0.localizedCaseInsensitiveContains(t) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Search cards, threads, and flows")
                        .font(AppFont.caption)
                        .foregroundStyle(palette.muted)
                    searchField
                }

                if isQuerying {
                    ProgressView()
                        .tint(chrome == .lightPaper ? UndrmndPrototypeTheme.primary : FogMapShellChrome.mapInkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                if let searchError {
                    Text(searchError)
                        .font(AppFont.caption)
                        .foregroundStyle(palette.muted)
                }

                liveResultsSection

                Text("Jump to a topic or flow")
                    .font(AppFont.caption2)
                    .foregroundStyle(palette.muted)

                if filteredPresets.isEmpty, !searchQuery.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("No preset matches for that filter.")
                        .font(AppFont.caption)
                        .foregroundStyle(palette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }

                ForEach(filteredPresets, id: \.0) { label, route in
                    Button {
                        onPick(.home(route), label)
                    } label: {
                        searchRow(title: label, subtitle: nil, chevron: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open \(label)")
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(palette.presetRowDivider)
                            .frame(height: 1)
                    }
                }
            }
            .padding(contentPadding)
        }
        .scrollIndicators(scrollIndicators)
        .background(palette.canvas)
        .task(id: searchQuery.wrappedValue) {
            await runLiveSearch()
        }
        .onAppear {
            guard autoFocusOnAppear, searchFieldFocus == nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                internalSearchFocus = true
            }
        }
    }

    @ViewBuilder
    private var searchField: some View {
        let field = searchFieldControl
        if let searchFieldFocus {
            field.focused(searchFieldFocus)
        } else {
            field.focused($internalSearchFocus)
        }
    }

    private var searchFieldControl: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(palette.muted)
            Group {
                if palette.usesFogFieldInk {
                    TextField("Type at least two characters to search the library", text: searchQuery)
                        .fogMapSearchFieldInk()
                } else {
                    TextField("Type at least two characters to search the library", text: searchQuery)
                        .foregroundStyle(palette.primary)
                }
            }
            .textFieldStyle(.plain)
            .font(AppFont.body)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.search)
            .keyboardType(.default)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.fieldPanel)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(palette.divider, lineWidth: 1)
                .allowsHitTesting(false)
        )
    }

    @ViewBuilder
    private var liveResultsSection: some View {
        let trimmed = searchQuery.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 2 {
            if !scoredContent.isEmpty {
                sectionHeader("From the library")
                ForEach(scoredContent) { hit in
                    Button {
                        onPick(.home(.articleForCard(hit.item.id)), hit.item.title)
                    } label: {
                        searchRow(title: hit.item.title, subtitle: hit.item.hook, chevron: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open card: \(hit.item.title)")
                }
            }

            if !scoredThreads.isEmpty {
                sectionHeader("Community threads")
                ForEach(scoredThreads) { hit in
                    Button {
                        onPick(.communityThread(hit.row.id), hit.row.title)
                    } label: {
                        searchRow(
                            title: hit.row.title,
                            subtitle: CommunityService.pillar(fromTopicColumn: hit.row.topic).displayName,
                            chevron: true
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open thread: \(hit.row.title)")
                }
            }

            if scoredContent.isEmpty, scoredThreads.isEmpty, !isQuerying, searchError == nil {
                Text("No library or thread matches yet. Try another word or jump to a topic below.")
                    .font(AppFont.caption)
                    .foregroundStyle(palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.emptyStatePanel)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(palette.divider, lineWidth: 1)
                    )
            }

            if let embeddingDiagnostic {
                Text(embeddingDiagnostic)
                    .font(AppFont.caption2)
                    .foregroundStyle(palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Supabase finds candidates; on-device embeddings from Apple NaturalLanguage re-rank by meaning (no generative text).")
                .font(AppFont.caption2)
                .foregroundStyle(palette.muted)
                .padding(.top, 2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AppFont.subheadlineEmphasis)
            .foregroundStyle(palette.primary)
            .padding(.top, 4)
    }

    private func searchRow(title: String, subtitle: String?, chevron: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.subheadline)
                    .foregroundStyle(palette.primary)
                    .multilineTextAlignment(.leading)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundStyle(palette.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 8)
            if chevron {
                Image(systemName: "chevron.right")
                    .font(AppFont.caption)
                    .foregroundStyle(palette.muted)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(palette.presetRowDivider)
                .frame(height: 1)
        }
    }

    @MainActor
    private func runLiveSearch() async {
        let raw = searchQuery.wrappedValue
        try? await Task.sleep(nanoseconds: 350_000_000)
        guard !Task.isCancelled else { return }

        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 2 else {
            scoredContent = []
            scoredThreads = []
            searchError = nil
            isQuerying = false
            embeddingDiagnostic = nil
            return
        }

        isQuerying = true
        searchError = nil
        defer { isQuerying = false }

        do {
            async let itemsTask = ContentService.searchContentItems(query: t, limit: 14)
            let threads = (try? await CommunityService.listAllThreadsForSearch(limit: 80)) ?? []

            let items = try await itemsTask
            let docForItem: (ContentItem) -> String = { "\($0.title) \($0.hook)" }
            scoredContent = items
                .map { ScoredContentHit(item: $0, score: SemanticSearchRanker.embeddingSimilarity(query: t, document: docForItem($0))) }
                .sorted { $0.score > $1.score }

            let threadHits: [ScoredThreadHit] = threads.compactMap { row in
                let doc = "\(row.title) \(row.topic) \(row.lastPostHandle ?? "") \(row.createdByHandle ?? "")"
                let sim = SemanticSearchRanker.embeddingSimilarity(query: t, document: doc)
                let substring =
                    row.title.localizedStandardContains(t)
                    || row.topic.localizedStandardContains(t)
                guard sim >= 0.17 || substring else { return nil }
                let score = substring ? max(sim, 0.26) : sim
                return ScoredThreadHit(row: row, score: score)
            }
            scoredThreads = threadHits.sorted { $0.score > $1.score }

            let mode = SemanticSearchRanker.isSentenceEmbeddingAvailable ? "sentence" : "word-average"
            embeddingDiagnostic = "Semantic index: on-device (\(mode))."
        } catch {
            scoredContent = []
            scoredThreads = []
            embeddingDiagnostic = nil
            searchError = "Library search didn’t complete. Check your connection and try again."
        }
    }
}
