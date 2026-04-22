import SwiftUI

// MARK: - “About” — why this app exists (short cards; calm, not a marketing wall)

struct AboutUndrmndView: View {
    @Environment(\.openTerritoryMapFromShell) private var openTerritoryMap
    @Environment(\.openTopicSearchFromShell) private var openTopicSearch
    @Environment(\.openAlertsFromShell) private var openAlertsFromShell

    private let cards: [(String, String)] = [
        (
            "What undrmnd is for",
            "undrmnd is a mindful place to explore ideas and science without the pull of an endless feed. It’s built for real curiosity, short sessions, and small contributions to learning — not for maximizing time in the app."
        ),
        (
            "Doomscrolling, by design, isn’t here",
            "There’s no endless scroll, streak pressure, or surprise notifications to hook you. Friction is intentional: you choose when to start, when to stop, and when to come back."
        ),
        (
            "How sessions work",
            "You might follow a path, try a set of open-topic cards, or read on your own. Each flow is meant to end in a clear place so your attention is yours to keep."
        ),
        (
            "Your privacy",
            "We don’t add tracking SDKs. Account details stay minimal, and the product is built to respect attention and consent — you’ll see that in how the app is wired, not in fine print you have to hunt for."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("About")
                    .font(AppFont.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)

                Text("A little context before you explore")
                    .font(AppFont.title2)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)

                ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(card.0)
                            .font(AppFont.subheadlineEmphasis)
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                        Text(card.1)
                            .font(AppFont.subheadline)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(UndrmndPrototypeTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                    )
                }
            }
            .padding(20)
            .padding(.bottom, 32)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand("About")
        .toolbar {
            ExploreShellToolbar.items(openMap: openTerritoryMap, openSearch: openTopicSearch, openAlerts: openAlertsFromShell)
        }
    }
}

#Preview {
    NavigationStack {
        AboutUndrmndView()
    }
}
