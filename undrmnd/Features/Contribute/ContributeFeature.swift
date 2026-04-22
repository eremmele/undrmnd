import SwiftUI

// MARK: - Hub
//
// Pillar-scoped discussions, backed by Supabase `contribute_threads` +
// `contribute_posts` via the `list_contribute_threads` / `get_contribute_thread`
// RPCs. Every thread is a question; replies live in a light "canvas chat" shape.
//
// Writing is read-only at the DB layer until sign-in lands (RLS requires
// `auth.uid() = author_user_id`). The draft box below preserves a local,
// on-device-only reply so the surface still feels alive.

struct ContributeView: View {
    @State private var selectedPillar: Pillar = .cosmos
    @State private var threads: [ContributeThread] = []
    @State private var isLoading: Bool = false
    @State private var loadError: String?

    private var filtered: [ContributeThread] {
        threads.filter { $0.topic == selectedPillar }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Pillar-scoped discussions: each thread is a question other readers are thinking through. Replies stay in plain prose — no reactions, no scores.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Picker("Pillar", selection: $selectedPillar) {
                    ForEach(Pillar.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Choose pillar: Cosmos, Living World, Mind and Brain, or How we know")

                if isLoading && threads.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else if let msg = loadError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Couldn’t load threads")
                            .font(AppFont.subheadlineEmphasis)
                        Text(msg)
                            .font(AppFont.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        Button("Try again") {
                            Task { await loadThreads() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                    )
                } else if filtered.isEmpty {
                    Text("No threads in this pillar yet.")
                        .font(AppFont.subheadline)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else {
                    ForEach(filtered) { thread in
                        NavigationLink {
                            ContributeThreadDetailView(threadId: thread.id, threadPreview: thread)
                        } label: {
                            CanvasThreadRowCard(thread: thread)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitle("Contribute")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadThreads() }
        .task { await loadThreads() }
    }

    private func loadThreads() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            threads = try await ContributeService.listThreads(pillar: nil, limit: 50)
        } catch {
            loadError = error.localizedDescription
        }
    }
}

// MARK: - List row: "canvas chat" shape

private struct CanvasThreadRowCard: View {
    let thread: ContributeThread

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(PillarColor.accent(for: thread.topic))
                .frame(width: 4)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(thread.title)
                    .font(AppFont.headline)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 6) {
                    Text(replyCountLabel)
                        .font(AppFont.caption2)
                    Text("·")
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                    Text(lastActivityLabel)
                        .font(AppFont.caption2)
                }
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                Text("started by @\(thread.createdByHandle)")
                    .font(AppFont.caption2)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(UndrmndPrototypeTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(thread.topic.displayName) discussion: \(thread.title), \(replyCountLabel), last active \(lastActivityLabel)")
    }

    // `post_count` includes the opening post; replies = total − 1.
    private var replyCountLabel: String {
        let total = thread.postCount ?? 0
        let replies = max(0, total - 1)
        return replies == 1 ? "1 reply" : "\(replies) replies"
    }

    private var lastActivityLabel: String {
        RelativeTime.label(from: thread.lastPostAt ?? thread.updatedAt)
    }
}

// MARK: - Pillar tints (subtle, print-friendly)

private enum PillarColor {
    static func accent(for p: Pillar) -> Color {
        switch p {
        case .cosmos: return Color(red: 0.25, green: 0.32, blue: 0.42)
        case .livingWorld: return Color(red: 0.2, green: 0.4, blue: 0.32)
        case .mindAndBrain: return Color(red: 0.38, green: 0.28, blue: 0.42)
        case .howWeKnow: return Color(red: 0.35, green: 0.33, blue: 0.28)
        }
    }
}

// MARK: - Relative timestamps
//
// Small helper kept local to this feature to avoid pulling in a formatter
// dependency elsewhere. Uses the user's locale but keeps phrasing calm.

private enum RelativeTime {
    static let formatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    static func label(from date: Date) -> String {
        formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Thread detail

struct ContributeThreadDetailView: View {
    let threadId: UUID
    /// Preview row from the list, used for instant title/topic while posts load.
    let threadPreview: ContributeThread?

    @State private var bundle: ContributeThreadBundle?
    @State private var isLoading: Bool = false
    @State private var loadError: String?
    @State private var localReplies: [LocalReply] = []
    @State private var draft: String = ""

    private struct LocalReply: Identifiable, Hashable {
        let id: UUID = UUID()
        let body: String
        let createdAt: Date = Date()
    }

    private var displayThread: ContributeThread? { bundle?.thread ?? threadPreview }
    private var serverPosts: [ContributePost] { bundle?.posts ?? [] }
    private var openingPost: ContributePost? { serverPosts.first(where: { $0.isOpening }) }
    private var replyPosts: [ContributePost] { serverPosts.filter { !$0.isOpening } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if isLoading && bundle == nil {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else if let msg = loadError {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Couldn’t load this thread")
                            .font(AppFont.subheadlineEmphasis)
                        Text(msg)
                            .font(AppFont.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        Button("Try again") {
                            Task { await loadThread() }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(UndrmndPrototypeTheme.panel)
                } else {
                    if let opening = openingPost {
                        openingPostBlock(opening)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Replies")
                            .font(AppFont.subheadlineEmphasis)
                            .padding(.bottom, 8)
                        ForEach(replyPosts) { post in
                            serverReplyRow(post)
                        }
                        ForEach(localReplies) { r in
                            localReplyRow(r)
                        }
                    }
                    .padding(.top, 8)

                    replyComposer
                }
            }
            .padding(20)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadThread() }
    }

    // MARK: Subviews

    @ViewBuilder private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let topic = displayThread?.topic {
                Text(topic.displayName.uppercased())
                    .font(AppFont.caption2Emphasis)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
            }
            Text(displayThread?.title ?? "Thread")
                .font(AppFont.title3)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
            if let handle = displayThread?.createdByHandle {
                Text("started by @\(handle)")
                    .font(AppFont.caption2)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openingPostBlock(_ p: ContributePost) -> some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill((displayThread.map { PillarColor.accent(for: $0.topic) } ?? UndrmndPrototypeTheme.divider).opacity(0.85))
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 6) {
                Text("@\(p.authorHandle) opened this thread")
                    .font(AppFont.caption2Emphasis)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
                Text(p.body)
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                Text(RelativeTime.label(from: p.createdAt))
                    .font(AppFont.caption2)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .background(UndrmndPrototypeTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
        )
    }

    private func serverReplyRow(_ p: ContributePost) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(UndrmndPrototypeTheme.divider)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@\(p.authorHandle)")
                        .font(AppFont.captionEmphasis)
                    Spacer()
                    Text(RelativeTime.label(from: p.createdAt))
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                Text(p.body)
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(UndrmndPrototypeTheme.divider)
                .frame(height: 0.5)
        }
    }

    private func localReplyRow(_ r: LocalReply) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(UndrmndPrototypeTheme.divider)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("@you (local)")
                        .font(AppFont.captionEmphasis)
                    Spacer()
                    Text("just now")
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                Text(r.body)
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(UndrmndPrototypeTheme.divider)
                .frame(height: 0.5)
        }
    }

    @ViewBuilder private var replyComposer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a reply")
                .font(AppFont.subheadlineEmphasis)
            Text("Stored on this device for now — posting to the shared thread turns on after sign-in.")
                .font(AppFont.caption2)
                .foregroundStyle(UndrmndPrototypeTheme.muted)
            TextField("Write a thoughtful reply…", text: $draft, axis: .vertical)
                .lineLimit(3...8)
                .padding(10)
                .background(UndrmndPrototypeTheme.panel)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                )
            Button {
                let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !t.isEmpty else { return }
                localReplies.append(LocalReply(body: t))
                draft = ""
            } label: {
                Text("Post reply")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LargeProminentPathButtonStyle())
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.top, 4)
    }

    // MARK: Loading

    private func loadThread() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        do {
            bundle = try await ContributeService.fetchThread(id: threadId)
        } catch {
            loadError = error.localizedDescription
        }
    }
}
