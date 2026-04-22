import SwiftUI

struct PublicProfileView: View {
    let username: String
    @State private var profile: Profile?
    @State private var cards: [ContentListRow] = []
    @State private var pathNodes: [PathNodeRow] = []
    @State private var pathTitles: [UUID: String] = [:]
    @State private var error: String?

    var body: some View {
        Group {
            if let p = profile {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.displayName ?? p.username)
                                .font(AppFont.title2)
                            Text("@\(p.username)")
                                .font(AppFont.subheadline)
                                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        }
                        if let b = p.bio, !b.isEmpty { Text(b).font(AppFont.body) }
                        if !p.pillarsFollowing.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Following")
                                    .font(AppFont.caption)
                                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                                ForEach(p.pillarsFollowing.map(\.displayName), id: \.self) { t in
                                    Text(t)
                                        .font(AppFont.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(UndrmndPrototypeTheme.panel)
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Contributions")
                                .font(AppFont.headline)
                            ForEach(cards) { c in
                                NavigationLink {
                                    ContentDetailReadOnlyView(contentId: c.id)
                                } label: {
                                    Text(c.title)
                                        .font(AppFont.subheadline)
                                }
                            }
                        }
                        if !pathNodes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("On paths")
                                    .font(AppFont.headline)
                                ForEach(pathNodes) { n in
                                    let title = pathTitles[n.pathId] ?? "Path"
                                    Text("\(title) · \(n.branchPrompt ?? "node")")
                                        .font(AppFont.caption)
                                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            } else if let error {
                Text(error).padding()
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand("Profile")
        .task { await load() }
    }

    private func load() async {
        do {
            profile = try await ProfileService.fetchProfile(username: username)
            if let p = profile {
                cards = try await ProfileService.fetchContributedCards(username: p.username)
                pathNodes = try await ProfileService.fetchAuthoredPathNodes(username: p.username)
                pathTitles = try await ProfileService.pathTitles(for: pathNodes.map(\.pathId))
            }
        } catch {
            self.error = "Profile not found or unavailable."
        }
    }
}
