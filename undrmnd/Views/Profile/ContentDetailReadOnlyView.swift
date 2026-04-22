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
                            .font(AppFont.title3)
                        Text(item.hook)
                            .font(AppFont.subheadline)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        if let b = item.body, !b.isEmpty {
                            Text(b)
                                .font(AppFont.body)
                                .lineSpacing(5)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 22)
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
