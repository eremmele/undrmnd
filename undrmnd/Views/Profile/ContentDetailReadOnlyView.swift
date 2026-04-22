import SwiftUI

/// Single-card read-only (profile tap-through); no play metrics or “next” prompts.
struct ContentDetailReadOnlyView: View {
    let contentId: UUID
    @State private var item: ContentItem?
    @State private var error: String?

    var body: some View {
        Group {
            if let item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.title)
                            .font(.title3.weight(.medium))
                        Text(item.hook)
                            .font(.subheadline)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        if let b = item.body, !b.isEmpty {
                            Text(b)
                                .font(.body)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }
            } else if let error {
                Text(error).padding()
            } else {
                ProgressView()
            }
        }
        .background(UndrmndPrototypeTheme.paper)
        .task { await load() }
    }

    private func load() async {
        do {
            item = try await ContentService.fetchCardDetail(id: contentId)
        } catch {
            self.error = "Couldn’t load this card."
        }
    }
}
