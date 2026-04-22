import SwiftUI

/// Chooses a live path from the database or a three-card open-question set with an optional pillar bias.
struct GoalClarifierView: View {
    var onSelectPath: (String) -> Void
    var onThreeCardSession: (Pillar?) -> Void

    @State private var activePaths: [PathRecord] = []
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("What are you looking for?")
                    .font(AppFont.title2)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)

                if !activePaths.isEmpty {
                    Text("Start with a path")
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
                            .padding(12)
                            .background(UndrmndPrototypeTheme.panel)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("No paths are available right now. You can use three open questions by pillar, or return after new paths are published to the app.")
                        .font(AppFont.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Or: three open questions, by pillar")
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
            .padding(20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        do {
            activePaths = try await PathService.fetchActivePaths()
        } catch {
            loadError = "Couldn’t list paths. \(error.localizedDescription)"
        }
    }
}
