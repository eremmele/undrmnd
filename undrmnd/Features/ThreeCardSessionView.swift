import SwiftUI

/// Finite three-card “open question” session: no autoplay, no “one more” in-app.
struct ThreeCardSessionView: View {
    /// When set, we bias selection toward this pillar. The database RPC is unfiltered, so we over-fetch and filter.
    var topicFilter: Pillar?

    @Environment(\.dismiss) private var dismiss
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
                        .font(.title3.weight(.medium))
                    Text("There isn’t another card lined up. When you want more, go home and start a new session—on purpose.")
                        .font(.subheadline)
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
                ProgressView("Drawing three cards…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if step < 3, items.indices.contains(step) {
                stepView(preview: items[step])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitle("Three open questions")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    @ViewBuilder
    private func stepView(preview: ContentPreview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card \(step + 1) of 3")
                .font(.caption)
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
            if let d = detail {
                Text(d.title)
                    .font(.title3.weight(.medium))
                Text(d.hook)
                    .font(.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                if let b = d.body, !b.isEmpty {
                    Text(b)
                        .font(.body)
                }
            } else {
                Text(preview.title)
                    .font(.title3.weight(.medium))
                Text(preview.hook)
                    .font(.subheadline)
            }
            Spacer()
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
        .padding(20)
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
