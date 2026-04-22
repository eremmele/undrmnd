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
                    .font(.title2.weight(.medium))
                    .foregroundStyle(UndrmndPrototypeTheme.primary)

                if !activePaths.isEmpty {
                    Text("Start with a path")
                        .font(.subheadline.weight(.medium))
                    ForEach(activePaths, id: \.id) { p in
                        Button {
                            onSelectPath(p.slug)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                if let s = p.subtitle, !s.isEmpty {
                                    Text(s)
                                        .font(.caption)
                                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                                }
                                Text(p.title)
                                    .font(.subheadline.weight(.medium))
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
                    Text("No paths are active in the project yet. You can still use three open questions, or check back after editorial turns paths on in Supabase.")
                        .font(.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Or: three open questions, by pillar")
                        .font(.subheadline.weight(.medium))
                    ForEach(Pillar.allCases) { pillar in
                        Button {
                            onThreeCardSession(pillar)
                        } label: {
                            Text("Explore \(pillar.displayName) — three cards, then stop")
                                .font(.caption)
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
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                }

                if let loadError {
                    Text(loadError)
                        .font(.caption)
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
