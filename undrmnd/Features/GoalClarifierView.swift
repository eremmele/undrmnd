import SwiftUI

/// Explore goal entry — same library / thread / preset search as the shell sheet, in fog ink over the map.
struct GoalClarifierView: View {
    var onSelectPath: (String) -> Void
    var onThreeCardSession: (Pillar?) -> Void
    var onCommunityThread: (UUID) -> Void

    @Environment(\.exploreUsesFogBackdrop) private var exploreUsesFogBackdrop
    @Environment(\.openArticleForContent) private var openArticleForContent

    var body: some View {
        Group {
            if exploreUsesFogBackdrop {
                TopicSearchView(chrome: .exploreFog) { pick, _ in
                    handlePick(pick)
                }
                .navigationTitleBrandFog("Search")
            } else {
                TopicSearchView(chrome: .lightPaper) { pick, _ in
                    handlePick(pick)
                }
                .navigationTitleBrand("Search")
            }
        }
    }

    private func handlePick(_ pick: GlobalSearchPick) {
        switch pick {
        case .home(let route):
            switch route {
            case .path(let slug):
                onSelectPath(slug)
            case .threeCard(let pillar):
                onThreeCardSession(pillar)
            case .articleForCard(let id):
                openArticleForContent(id)
            case .goalClarifier, .territoryMap, .about:
                break
            }
        case .communityThread(let id):
            onCommunityThread(id)
        }
    }
}
