import SwiftUI

/// Open-topic card session: no autoplay, no “one more” in-app.
struct ThreeCardSessionView: View {
    /// When set, we bias selection toward this pillar. The database RPC is unfiltered, so we over-fetch and filter.
    var topicFilter: Pillar?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openArticleForContent) private var openArticleForContent
    @Environment(\.exploreUsesFogBackdrop) private var exploreUsesFogBackdrop
    @State private var items: [ContentPreview] = []
    @State private var step: Int = 0
    @State private var error: String?
    @State private var detail: ContentItem?
    @State private var isDone: Bool = false

    private var cardInkTitle: Color {
        exploreUsesFogBackdrop ? ExploreFogNavigationInk.title : UndrmndPrototypeTheme.primary
    }

    private var cardInkSecondary: Color {
        exploreUsesFogBackdrop ? ExploreFogNavigationInk.secondary : UndrmndPrototypeTheme.secondary
    }

    private var cardCaption: Color {
        exploreUsesFogBackdrop ? ExploreFogNavigationInk.muted : UndrmndPrototypeTheme.secondary
    }

    @ViewBuilder
    private var sessionStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isDone {
                VStack(alignment: .center, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .center, spacing: 16) {
                            Text("You’re done with this set.")
                                .font(AppFont.title3)
                                .foregroundStyle(cardInkTitle)
                            Text("That’s the end of this set. When you want more, go home and start a new session on purpose.")
                                .font(AppFont.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(cardInkSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        .padding(.horizontal, 24)
                        .padding(.top, 22)
                    }
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(UndrmndPrototypeTheme.divider)
                            .frame(height: 0.5)
                        Button("Back to home") { dismiss() }
                            .buttonStyle(LargeProminentPathButtonStyle())
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .padding(.bottom, 10)
                    }
                    .background(UndrmndPrototypeTheme.paper)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else if let err = error {
                VStack(spacing: 12) {
                    Text(err)
                        .font(AppFont.body)
                        .foregroundStyle(cardInkSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(28)
            } else if items.isEmpty {
                if exploreUsesFogBackdrop {
                    ProgressView("Loading topics…")
                        .tint(FogMapShellChrome.mapInkSoft)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView("Loading topics…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if step < 3, items.indices.contains(step) {
                cardStepView(preview: items[step])
            }
        }
    }

    var body: some View {
        Group {
            if exploreUsesFogBackdrop {
                sessionStack.navigationTitleBrandFog("Open topics")
            } else {
                sessionStack.navigationTitleBrand("Open topics")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(exploreUsesFogBackdrop ? Color.clear : UndrmndPrototypeTheme.paper)
        .task { await load() }
    }

    @ViewBuilder
    private func openTheWorkButton(contentId: UUID) -> some View {
        Button {
            openArticleForContent(contentId)
        } label: {
            Text("Open the work")
        }
        .buttonStyle(OpenTheWorkCTAButtonStyle())
        .accessibilityLabel("Open the work, full article")
    }

    /// Design-only sample links for the first card in a set. Replace with real `content_items` / article URLs when available.
    @ViewBuilder
    private func openingCardPrimarySourceLinks() -> some View {
        HStack(alignment: .center, spacing: 8) {
            if let u1 = URL(string: "https://en.wikipedia.org/wiki/Dark_matter"),
               let u2 = URL(string: "https://en.wikipedia.org/wiki/Weakly_interacting_massive_particles") {
                Link("primary source 1", destination: u1)
                    .openTopicsPrimarySourcePill()
                Link("primary source 2", destination: u2)
                    .openTopicsPrimarySourcePill()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    @ViewBuilder
    private func nextOrFinishButton(preview: ContentPreview) -> some View {
        Button {
            if step == 2 {
                isDone = true
            } else {
                let next = step + 1
                step = next
                detail = nil
                Task { await loadDetail(for: items[next]) }
            }
        } label: {
            Text(step == 2 ? "Finish" : "Next")
        }
        .buttonStyle(LargeProminentPathButtonStyle())
        .accessibilityLabel(step == 2 ? "Finish this set" : "Next card")
    }

    /// Content scrolls; primary CTA is pinned in the thumb zone above the tab bar (not inside `ScrollView`, so it doesn’t jump when body text length changes or when advancing steps).
    @ViewBuilder
    private func cardStepView(preview: ContentPreview) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(step + 1) of 3")
                        .font(AppFont.caption)
                        .foregroundStyle(cardCaption)
                    if let d = detail {
                        Text(d.title)
                            .font(AppFont.title3)
                            .foregroundStyle(cardInkTitle)
                        Text(d.hook)
                            .font(AppFont.subheadline)
                            .foregroundStyle(cardInkSecondary)
                        if let b = d.body, !b.isEmpty {
                            Text(b)
                                .font(AppFont.body)
                                .foregroundStyle(cardInkSecondary)
                                .lineSpacing(5)
                        }
                    } else {
                        Text(preview.title)
                            .font(AppFont.title3)
                            .foregroundStyle(cardInkTitle)
                        Text(preview.hook)
                            .font(AppFont.subheadline)
                            .foregroundStyle(cardInkSecondary)
                    }
                    if step == 0 {
                        openingCardPrimarySourceLinks()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 20)
            }

            VStack(spacing: 0) {
                Rectangle()
                    .fill(UndrmndPrototypeTheme.divider)
                    .frame(height: 0.5)
                let currentCardId = detail?.id ?? preview.id
                Group {
                    if horizontalSizeClass == .regular {
                        HStack(spacing: 12) {
                            openTheWorkButton(contentId: currentCardId)
                            nextOrFinishButton(preview: preview)
                        }
                    } else {
                        VStack(spacing: 10) {
                            openTheWorkButton(contentId: currentCardId)
                            nextOrFinishButton(preview: preview)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 10)
            }
            .background(UndrmndPrototypeTheme.paper)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

// MARK: - Open topics primary source pills (first card)

private extension View {
    func openTopicsPrimarySourcePill() -> some View {
        self
            .font(AppFont.caption2Emphasis)
            .foregroundStyle(UndrmndPrototypeTheme.paper)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(UndrmndPrototypeTheme.accent, in: Capsule())
    }
}
