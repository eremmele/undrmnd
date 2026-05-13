import SwiftUI
import Supabase

/// Full-bleed article for a `content_items` id (the “Open the work” surface).
struct ArticleView: View {
    let contentId: UUID

    @State private var bundle: ArticleBundle?
    @State private var loadError: String?
    @State private var isLoading = true
    @State private var showEdit = false
    @State private var branchToFork: ArticleBranch?

    var body: some View {
        Group {
            if isLoading, bundle == nil, loadError == nil {
                ProgressView("Loading")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = loadError {
                VStack(spacing: 16) {
                    Text(err)
                        .font(AppFont.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    Button("Try again") {
                        Task { await load(force: true) }
                    }
                    .buttonStyle(LargeProminentPathButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(24)
            } else if let b = bundle {
                articleBody(b)
            } else {
                Text("Nothing to show.")
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitle(bundle.map(\.article.title) ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: contentId) {
            await load(force: false)
        }
        .refreshable {
            await load(force: true)
        }
        .fullScreenCover(isPresented: $showEdit) {
            Group {
                if let b = bundle {
                    ArticleEditSheet(
                        articleId: b.article.id,
                        bodyMarkdown: b.version.bodyMarkdown
                    ) {
                        showEdit = false
                    }
                } else {
                    Color.clear.onAppear { showEdit = false }
                }
            }
        }
        .sheet(item: $branchToFork) { branch in
            if let b = bundle {
                ArticleForkSheet(
                    branch: branch,
                    defaultArticleTitle: b.article.title,
                    pillar: b.article.pillar
                ) { branchToFork = nil }
            }
        }
    }

    @ViewBuilder
    private func articleBody(_ b: ArticleBundle) -> some View {
        let readMinutes = readTimeMinutes(b.version.bodyMarkdown)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroSection(article: b.article)
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 6) {
                        Text(b.article.pillar.displayName)
                            .font(AppFont.caption2Emphasis)
                        Text("·")
                            .font(AppFont.caption2)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        if let m = readMinutes {
                            Text("\(m) min read")
                                .font(AppFont.caption2)
                        }
                    }
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
                    .padding(.top, 20)

                    Text(b.article.title)
                        .font(AppFont.title2)
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    bylineBlock(b.article)

                    if let cap = b.article.heroCaption, !cap.isEmpty {
                        Text(cap)
                            .font(AppFont.footnote)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    }

                    Rectangle()
                        .fill(UndrmndPrototypeTheme.divider)
                        .frame(height: 0.5)
                        .padding(.vertical, 4)

                    markdownBlock(b.version.bodyMarkdown)

                    primarySourcesBlock(b.primarySources)

                    Rectangle()
                        .fill(UndrmndPrototypeTheme.divider)
                        .frame(height: 0.5)
                        .padding(.vertical, 4)

                    openBranchesSection(article: b.article, branches: b.branches)

                    Rectangle()
                        .fill(UndrmndPrototypeTheme.divider)
                        .frame(height: 0.5)
                        .padding(.vertical, 4)

                    relatedCardsSection(cards: b.relatedCards)

                    Button {
                        showEdit = true
                    } label: {
                        Text("Edit this article")
                            .font(AppFont.bodySemibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(OpenTheWorkCTAButtonStyle())
                    .accessibilityLabel("Edit this article")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func heroSection(article: Article) -> some View {
        Group {
            if let href = article.heroImageUrl, let u = URL(string: href) {
                AsyncImage(url: u) { ph in
                    ph.resizable()
                        .scaledToFill()
                } placeholder: {
                    heroPlaceholder(article: article)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 200)
                .clipped()
            } else {
                heroPlaceholder(article: article)
            }
        }
        .frame(maxWidth: .infinity)
        .ignoresSafeArea(edges: .horizontal)
    }

    private func heroPlaceholder(article: Article) -> some View {
        ZStack {
            article.pillar.articleChromeWash
            Image(systemName: "photo")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(UndrmndPrototypeTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
    }

    @ViewBuilder
    private func bylineBlock(_ article: Article) -> some View {
        let h = article.authorHandle.hasPrefix("@")
            ? article.authorHandle
            : "@\(article.authorHandle)"
        Group {
            if let role = article.bylineRole, !role.isEmpty {
                (Text("by ") + Text(h).font(AppFont.captionEmphasis) + Text(", ") + Text(role).font(AppFont.caption))
            } else {
                (Text("by ") + Text(h).font(AppFont.captionEmphasis))
            }
        }
        .font(AppFont.caption)
        .foregroundStyle(UndrmndPrototypeTheme.secondary)
    }

    private func markdownBlock(_ md: String) -> some View {
        let text: Text = {
            if let attr = try? AttributedString(markdown: md) {
                return Text(attr)
            }
            return Text(md)
        }()
        return text
            .font(AppFont.body)
            .foregroundStyle(UndrmndPrototypeTheme.primary)
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func primarySourcesBlock(_ sources: [ArticlePrimarySource]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Primary sources")
                .font(AppFont.subheadlineEmphasis)
            ForEach(Array(sources.sorted { $0.orderIndex < $1.orderIndex }.enumerated()), id: \.offset) { _, s in
                if let u = s.url.flatMap({ URL(string: $0) }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Link(s.label, destination: u)
                            .font(AppFont.caption)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(s.label)
                            .font(AppFont.caption)
                        if let c = s.citation, !c.isEmpty {
                            Text(c)
                                .font(AppFont.caption2)
                                .foregroundStyle(UndrmndPrototypeTheme.muted)
                        }
                    }
                }
            }
        }
    }

    private func openBranchesSection(article: Article, branches: [ArticleBranch]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OPEN BRANCHES")
                .font(AppFont.mapLabel(approxSize: 10, mapWeight: .semibold))
                .tracking(0.06)
                .foregroundStyle(UndrmndPrototypeTheme.muted)
            ForEach(branches.sorted { $0.orderIndex < $1.orderIndex }) { br in
                branchCard(article: article, branch: br)
            }
        }
    }

    private func branchCard(article: Article, branch: ArticleBranch) -> some View {
        HStack(alignment: .top, spacing: 0) {
            article.pillar.articleStripe
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    tagPill(type: branch.contributionType)
                    Spacer(minLength: 0)
                }
                Text(branch.title)
                    .font(AppFont.subheadlineEmphasis)
                Text(branch.prompt)
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                Button {
                    branchToFork = branch
                } label: {
                    Text("Fork this →")
                }
                .buttonStyle(OpenTheWorkCTAButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .background(UndrmndPrototypeTheme.paper)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func tagPill(type: ArticleContributionType) -> some View {
        Text(type.rawValue.capitalized)
            .font(AppFont.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(UndrmndPrototypeTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 0.5)
            )
    }

    private func relatedCardsSection(cards: [ArticleRelatedCard]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Related cards")
                .font(AppFont.subheadlineEmphasis)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(cards.sorted { $0.orderIndex < $1.orderIndex }, id: \.contentId) { r in
                    NavigationLink {
                        ContentDetailReadOnlyView(contentId: r.contentId)
                    } label: {
                        HStack {
                            Text("Open related content")
                            Image(systemName: "chevron.right")
                                .font(AppFont.caption2)
                        }
                        .font(AppFont.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }

    private func readTimeMinutes(_ md: String) -> Int? {
        let w = md.split { $0.isWhitespace || $0.isNewline }.count
        guard w > 0 else { return nil }
        let minutes = max(1, (w + 219) / 220)
        return minutes
    }

    private func load(force: Bool) async {
        if force { isLoading = true }
        if !force, bundle != nil { isLoading = false; return }
        loadError = nil
        isLoading = true
        do {
            let b = try await ArticleService.fetchForCard(contentId: contentId)
            bundle = b
        } catch ArticleServiceError.noArticleForContent {
            loadError =
                "This card is not linked to a published article in the library yet. Try another dot on the map, or open a card from the home feed."
        } catch let e as ArticleServiceError {
            #if DEBUG
            print("ArticleView: ArticleServiceError for contentId \(contentId): \(e)")
            #endif
            loadError = "Could not load the article. Try again in a moment."
        } catch let url as URLError where url.code == .notConnectedToInternet {
            loadError = "You appear to be offline. Check your connection, then try again."
        } catch is DecodingError {
            #if DEBUG
            print("ArticleView: decode failed for contentId \(contentId)")
            #endif
            loadError =
                "The library returned data this build could not read. Pull to refresh, or update the app if the problem continues."
        } catch let pg as PostgrestError {
            #if DEBUG
            print("ArticleView: PostgREST \(pg.code ?? "?") for contentId \(contentId): \(pg.message)")
            #endif
            loadError = "Could not reach the library (\(pg.code ?? "error")). Try again in a moment."
        } catch {
            #if DEBUG
            print("ArticleView: failed to load article for contentId \(contentId): \(error)")
            #endif
            loadError = "Could not load the article. Try again in a moment."
        }
        isLoading = false
    }
}

// MARK: - Sheets

struct ArticleEditSheet: View {
    let articleId: UUID
    let bodyMarkdown: String
    var onClose: () -> Void

    @State private var bodyText: String
    @State private var commitMessage = ""
    @State private var inlineError: String?
    @State private var isSaving = false

    init(articleId: UUID, bodyMarkdown: String, onClose: @escaping () -> Void) {
        self.articleId = articleId
        self.bodyMarkdown = bodyMarkdown
        self.onClose = onClose
        _bodyText = State(initialValue: bodyMarkdown)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button("Close", action: onClose)
                        .font(AppFont.body)
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                    Spacer()
                }
                Text("Edit text")
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
                TextEditor(text: $bodyText)
                    .font(AppFont.body)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                            .allowsHitTesting(false)
                    )
                Text("Commit message (optional, max 280 characters)")
                    .font(AppFont.caption)
                TextField("What changed", text: $commitMessage)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: commitMessage) { _, s in
                        if s.count > 280 { commitMessage = String(s.prefix(280)) }
                    }
                if let e = inlineError {
                    Text(e)
                        .font(AppFont.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }
                Button {
                    Task { await save() }
                } label: {
                    Text("Commit version")
                }
                .buttonStyle(LargeProminentPathButtonStyle())
                .disabled(isSaving)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(24)
            .background(UndrmndPrototypeTheme.paper)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func save() async {
        isSaving = true
        inlineError = nil
        defer { isSaving = false }
        do {
            _ = try await ArticleService.commitVersion(
                articleId: articleId,
                body: bodyText,
                commitMessage: commitMessage.isEmpty ? nil : commitMessage
            )
            onClose()
        } catch ArticleServiceError.signInRequired {
            inlineError = "Sign in to commit"
        } catch {
            inlineError = "Sign in to commit"
        }
    }
}

struct ArticleForkSheet: View {
    let branch: ArticleBranch
    let defaultArticleTitle: String
    let pillar: Pillar
    var onClose: () -> Void

    @State private var title: String
    @State private var slug: String
    @State private var bodyText = ""
    @State private var inlineError: String?
    @State private var isSaving = false

    init(branch: ArticleBranch, defaultArticleTitle: String, pillar: Pillar, onClose: @escaping () -> Void) {
        self.branch = branch
        self.defaultArticleTitle = defaultArticleTitle
        self.pillar = pillar
        self.onClose = onClose
        _title = State(initialValue: branch.title)
        _slug = State(initialValue: ArticleForkSheet.slugify(branch.title))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button("Close", action: onClose)
                        .font(AppFont.body)
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                    Spacer()
                }
                Text("Title")
                    .font(AppFont.caption)
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: title) { _, t in
                        slug = ArticleForkSheet.slugify(t)
                    }
                Text("Slug")
                    .font(AppFont.caption)
                TextField("url-slug", text: $slug)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                Text("Body")
                    .font(AppFont.caption)
                TextEditor(text: $bodyText)
                    .font(AppFont.body)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(UndrmndPrototypeTheme.panel)
                if let e = inlineError {
                    Text(e)
                        .font(AppFont.caption)
                }
                Button {
                    Task { await save() }
                } label: {
                    Text("Create branch article")
                }
                .buttonStyle(LargeProminentPathButtonStyle())
                .disabled(isSaving)
            }
            .padding(24)
            .background(UndrmndPrototypeTheme.paper)
        }
    }

    private func save() async {
        isSaving = true
        inlineError = nil
        defer { isSaving = false }
        do {
            _ = try await ArticleService.forkBranch(
                branchId: branch.id,
                title: title,
                slug: slug,
                body: bodyText
            )
            onClose()
        } catch ArticleServiceError.signInRequired {
            inlineError = "Sign in to commit"
        } catch {
            inlineError = "Sign in to commit"
        }
    }

    private static func slugify(_ s: String) -> String {
        s.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}
