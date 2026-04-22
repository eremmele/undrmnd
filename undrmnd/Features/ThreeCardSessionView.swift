import SwiftUI

/// Open-topic card session: no autoplay, no “one more” in-app.
struct ThreeCardSessionView: View {
    /// When set, we bias selection toward this pillar. The database RPC is unfiltered, so we over-fetch and filter.
    var topicFilter: Pillar?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openTerritoryMapFromShell) private var openTerritoryMap
    @Environment(\.openTopicSearchFromShell) private var openTopicSearch
    @Environment(\.openAlertsFromShell) private var openAlertsFromShell
    @State private var items: [ContentPreview] = []
    @State private var step: Int = 0
    @State private var error: String?
    @State private var detail: ContentItem?
    @State private var isDone: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isDone {
                VStack(alignment: .center, spacing: 16) {
                    Text("You’re done for now.")
                        .font(AppFont.title3)
                    Text("There isn’t another card lined up. When you want more, go home and start a new session—on purpose.")
                        .font(AppFont.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    Button("Back to home") { dismiss() }
                        .buttonStyle(LargeProminentPathButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else if let err = error {
                Text(err).padding()
            } else if items.isEmpty {
                ProgressView("Loading topics…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if step < 3, items.indices.contains(step) {
                stepView(preview: items[step])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand("Open topics")
        .toolbar {
            ExploreShellToolbar.items(openMap: openTerritoryMap, openSearch: openTopicSearch, openAlerts: openAlertsFromShell)
        }
        .task { await load() }
    }

    @ViewBuilder
    private func stepView(preview: ContentPreview) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Card \(step + 1) of 3")
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                if let d = detail {
                    Text(d.title)
                        .font(AppFont.title3)
                    Text(d.hook)
                        .font(AppFont.subheadline)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    if let b = d.body, !b.isEmpty {
                        Text(b)
                            .font(AppFont.body)
                            .lineSpacing(5)
                    }
                } else {
                    Text(preview.title)
                        .font(AppFont.title3)
                    Text(preview.hook)
                        .font(AppFont.subheadline)
                }
                Button {
                    if step == 2 {
                        isDone = true
                    } else {
                        step += 1
                        detail = nil
                        Task { await loadDetail(for: items[step]) }
                    }
                } label: {
                    Text(step == 2 ? "Finish" : "Next")
                }
                .buttonStyle(LargeProminentPathButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
        }
        .task(id: step) {
            await loadDetail(for: preview)
        }
    }

    private func load() async {
        do {
            let pool = try await ContentService.fetchRandomCards(n: 18)
            var picked: [ContentPreview] = []
            if let t = topicFilter {
                picked = pool.filter { $0.topic == t }
            } else {
                picked = pool
            }
            if picked.count < 3 {
                picked = pool
            }
            items = Array(picked.prefix(3))
            if items.count < 3 {
                error = "Not enough cards to finish this session right now. Try again later."
            }
        } catch {
            self.error = "Couldn’t load cards. \(error.localizedDescription)"
        }
    }

    private func loadDetail(for p: ContentPreview) async {
        if let d = try? await ContentService.fetchCardDetail(id: p.id) {
            detail = d
        }
    }
}
