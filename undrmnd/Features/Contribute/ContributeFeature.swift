import SwiftUI
import UIKit

// MARK: - Models

/// A row from `content_items` when you have a UUID; otherwise the thread still shows title/hook for context.
struct ThreadContentItemRef: Identifiable, Hashable {
    /// If set, opens `ContentDetailReadOnlyView` against your Supabase `content_items` row.
    var databaseId: UUID?
    let title: String
    let hook: String
    let contributedBy: String

    var id: String {
        if let databaseId { return databaseId.uuidString }
        return title + "|" + hook
    }
}

struct ThreadReply: Identifiable, Hashable {
    let id: UUID
    let authorHandle: String
    let body: String
    let timeLabel: String
}

struct PillarDiscussionThread: Identifiable, Hashable {
    let id: UUID
    let pillar: Pillar
    /// Posed as a genuine question (title of the “forum topic”).
    let titleQuestion: String
    let contentItems: [ThreadContentItemRef]
    let seedReplies: [ThreadReply]
    let lastActivityLabel: String
}

// MARK: - Seed (copy aligned to v2 open-question cards; `databaseId` can be set once your DB ids are known)

enum ContributeSeedData {
    static let threads: [PillarDiscussionThread] = [
        PillarDiscussionThread(
            id: makeId("a0000001-0000-4000-8000-000000000001"),
            pillar: .cosmos,
            titleQuestion: "If WIMPs keep not showing up, what would you bet on next, and why?",
            contentItems: [
                ThreadContentItemRef(
                    databaseId: nil,
                    title: "What is dark matter, really?",
                    hook: "85% of the matter in the universe is invisible, and no one knows what it’s made of.",
                    contributedBy: "teo_ok"
                ),
                ThreadContentItemRef(
                    databaseId: nil,
                    title: "Why is the universe expanding faster than it should?",
                    hook: "Two trusted methods of measuring the universe’s expansion rate give two different numbers.",
                    contributedBy: "juno_rx"
                )
            ],
            seedReplies: [
                ThreadReply(
                    id: makeId("b0000001-0000-4000-8000-000000000001"),
                    authorHandle: "sage_m",
                    body: "I’m not betting money, but axion radio searches and stellar streams are where I’d look first, because they stress-test different failure modes of ΛCDM than direct-detection.",
                    timeLabel: "4 days ago"
                ),
                ThreadReply(
                    id: makeId("b0000001-0000-4000-8000-000000000002"),
                    authorHandle: "juno_rx",
                    body: "The tension might still be a measurement systematics story. I’d want one independent ladder that doesn’t share hardware assumptions before I’d claim new particle physics.",
                    timeLabel: "2 days ago"
                )
            ],
            lastActivityLabel: "2 days ago"
        ),
        PillarDiscussionThread(
            id: makeId("a0000001-0000-4000-8000-000000000002"),
            pillar: .cosmos,
            titleQuestion: "What would a discovery of Planet Nine change about how we teach the solar system?",
            contentItems: [
                ThreadContentItemRef(
                    databaseId: nil,
                    title: "Is there a Planet Nine hiding in our own solar system?",
                    hook: "The outer orbits of a handful of trans-Neptunian objects are clustered in a way nothing in the current solar system should cause.",
                    contributedBy: "teo_ok"
                )
            ],
            seedReplies: [
                ThreadReply(
                    id: makeId("b0000001-0000-4000-8000-000000000003"),
                    authorHandle: "nneka_o",
                    body: "It would be a good lesson in humility: textbooks would need a chapter on what we didn’t know about our own neighborhood.",
                    timeLabel: "1 week ago"
                )
            ],
            lastActivityLabel: "1 week ago"
        ),
        PillarDiscussionThread(
            id: makeId("a0000001-0000-4000-8000-000000000010"),
            pillar: .livingWorld,
            titleQuestion: "If “species on Earth” is still uncertain by orders of magnitude, what should a school lab count as success?",
            contentItems: [
                ThreadContentItemRef(
                    databaseId: nil,
                    title: "How many species share Earth with us? No one knows within a factor of 10.",
                    hook: "Estimates range from 2 million to a trillion. Most of the uncertainty is microbes.",
                    contributedBy: "nneka_o"
                ),
                ThreadContentItemRef(
                    databaseId: nil,
                    title: "Does the \"wood-wide web\" actually work the way Simard said?",
                    hook: "A 1997 Nature paper said trees trade carbon through fungal networks. A 2023 review says the evidence is thinner than popular science made it sound.",
                    contributedBy: "yuki_t"
                )
            ],
            seedReplies: [
                ThreadReply(
                    id: makeId("b0000001-0000-4000-8000-000000000010"),
                    authorHandle: "lina_sketches",
                    body: "We stopped grading “getting the right number” and started grading how you justify what you can and can’t know from one method.",
                    timeLabel: "3 days ago"
                )
            ],
            lastActivityLabel: "3 days ago"
        ),
        PillarDiscussionThread(
            id: makeId("a0000001-0000-4000-8000-000000000020"),
            pillar: .mindAndBrain,
            titleQuestion: "Is “attention” one working construct in your lab, or a bundle you stop naming?",
            contentItems: [
                ThreadContentItemRef(
                    databaseId: nil,
                    title: "Why do phones feel impossible to put down?",
                    hook: "Intermittent reinforcement: the same mechanic as slot machines. You don’t know when the next reward is coming, so you keep pulling.",
                    contributedBy: "juno_rx"
                ),
                ThreadContentItemRef(
                    databaseId: nil,
                    title: "Is consciousness something physics can describe?",
                    hook: "We don’t have a theory that explains why there’s a “what it’s like” to be you.",
                    contributedBy: "sage_m"
                )
            ],
            seedReplies: [
                ThreadReply(
                    id: makeId("b0000001-0000-4000-8000-000000000020"),
                    authorHandle: "bench_ethics",
                    body: "We picked one definition for the semester: sustained engagement with a target under distraction. It’s wrong for everyone’s subfield, but it’s checkable in class data.",
                    timeLabel: "5 days ago"
                ),
                ThreadReply(
                    id: makeId("b0000001-0000-4000-8000-000000000021"),
                    authorHandle: "orion_ledger",
                    body: "I stop naming it when I need students to look at a behavior without rehearsing a theory. Names can smuggle in assumptions.",
                    timeLabel: "4 days ago"
                )
            ],
            lastActivityLabel: "4 days ago"
        ),
        PillarDiscussionThread(
            id: makeId("a0000001-0000-4000-8000-000000000030"),
            pillar: .howWeKnow,
            titleQuestion: "What would make you disbelieve a citizen-science aggregate at class scale?",
            contentItems: [
                ThreadContentItemRef(
                    databaseId: nil,
                    title: "Why is the replication crisis not a scandal?",
                    hook: "Somewhere between 36% and 65% of published psychology findings don’t replicate. That’s not a failure. It’s the system working.",
                    contributedBy: "ilhan_b"
                ),
                ThreadContentItemRef(
                    databaseId: nil,
                    title: "What would it take for citizen science to just be called \"science\"?",
                    hook: "The data quality is already there. The gatekeeping is social, not technical.",
                    contributedBy: "teo_ok"
                )
            ],
            seedReplies: [
                ThreadReply(
                    id: makeId("b0000001-0000-4000-8000-000000000030"),
                    authorHandle: "sage_m",
                    body: "I’d disbelieve it if the pipeline can’t show me dropped rows, consent boundaries, and who can’t participate, not if one kid’s outlier is uncomfortable.",
                    timeLabel: "6 days ago"
                )
            ],
            lastActivityLabel: "6 days ago"
        )
    ]

    private static func makeId(_ s: String) -> UUID { UUID(uuidString: s)! }
}

// MARK: - Pillar bar (scrollable; avoids clipped segment titles)

private struct ContributePillarBar: View {
    @Binding var selection: Pillar

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Pillar.allCases) { pillar in
                    pillarChip(pillar)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background {
            Capsule(style: .continuous)
                .fill(UndrmndPrototypeTheme.panel)
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 0.5)
                )
        }
    }

    private func pillarChip(_ pillar: Pillar) -> some View {
        let selected = selection == pillar
        return Button {
            selection = pillar
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            Text(pillar.displayName)
                .font(AppFont.subheadline)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.88)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    Capsule(style: .continuous)
                        .fill(selected ? Color.white : Color.clear)
                        .shadow(color: selected ? Color.black.opacity(0.06) : .clear, radius: 2, y: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(pillar.displayName) pillar")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Hub

struct ContributeView: View {
    @State private var selectedPillar: Pillar = .cosmos
    private var filtered: [PillarDiscussionThread] {
        ContributeSeedData.threads.filter { $0.pillar == selectedPillar }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Each thread is an open discussion. Threads tie to one or more open-question cards so responses stay grounded.")
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ContributePillarBar(selection: $selectedPillar)

                if filtered.isEmpty {
                    Text("No threads in this pillar yet.")
                        .font(AppFont.subheadline)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else {
                    ForEach(filtered) { thread in
                        NavigationLink {
                            ContributeThreadDetailView(thread: thread)
                        } label: {
                            CanvasThreadRowCard(thread: thread)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 64)
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand("Contribute")
    }
}

// MARK: - List row: “canvas chat” shape

private struct CanvasThreadRowCard: View {
    let thread: PillarDiscussionThread

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(thread.titleQuestion)
                .font(AppFont.headline)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
                .multilineTextAlignment(.leading)
            HStack(spacing: 6) {
                Text("\(thread.seedReplies.count) replies")
                    .font(AppFont.caption2)
                Text("·")
                    .font(AppFont.caption2)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
                Text(thread.lastActivityLabel)
                    .font(AppFont.caption2)
            }
            .foregroundStyle(UndrmndPrototypeTheme.muted)
            if thread.contentItems.count > 1 {
                Text("\(thread.contentItems.count) cards in thread")
                    .font(AppFont.caption2)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
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
        .accessibilityLabel("\(thread.pillar.displayName) discussion: \(thread.titleQuestion), \(thread.seedReplies.count) replies, last active \(thread.lastActivityLabel)")
    }
}

// MARK: - Thread detail

struct ContributeThreadDetailView: View {
    let thread: PillarDiscussionThread

    @State private var extraReplies: [ThreadReply] = []
    @State private var draft: String = ""
    @FocusState private var replyFieldFocused: Bool

    private var allReplies: [ThreadReply] { thread.seedReplies + extraReplies }
    private var canSendReply: Bool { !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(thread.pillar.displayName.uppercased())
                            .font(AppFont.caption2Emphasis)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        Text(thread.titleQuestion)
                            .font(AppFont.title3)
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Open-question cards in this thread")
                            .font(AppFont.subheadlineEmphasis)
                        Text("Replies are meant in the context of these cards. Multiple cards are allowed so the same conversation can sit across a short path of readings.")
                            .font(AppFont.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        ForEach(thread.contentItems) { ref in
                            if let db = ref.databaseId {
                                NavigationLink {
                                    ContentDetailReadOnlyView(contentId: db)
                                } label: {
                                    contentCardBlock(ref, isLink: true)
                                }
                                .buttonStyle(.plain)
                            } else {
                                contentCardBlock(ref, isLink: false)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Replies")
                            .font(AppFont.subheadlineEmphasis)
                            .padding(.bottom, 8)
                        ForEach(allReplies) { r in
                            forumReplyRow(r)
                        }
                    }
                    .padding(.top, 8)

                    Color.clear.frame(height: 1).id("threadBottom")
                }
                .padding(20)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: replyFieldFocused) { _, on in
                if on {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            proxy.scrollTo("threadBottom", anchor: .bottom)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                messagesStyleReplyBar(proxy: proxy)
            }
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func messagesStyleReplyBar(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(UndrmndPrototypeTheme.divider)
                .frame(height: 0.5)
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Reply", text: $draft, axis: .vertical)
                    .lineLimit(1...6)
                    .textFieldStyle(.plain)
                    .font(AppFont.subheadline)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .focused($replyFieldFocused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(UndrmndPrototypeTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                    )
                    .accessibilityLabel("Reply")
                    .accessibilityHint("Type your message, then double tap Send to post")
                Button {
                    postReply(proxy: proxy)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(canSendReply ? UndrmndPrototypeTheme.accent : UndrmndPrototypeTheme.muted)
                }
                .buttonStyle(.plain)
                .disabled(!canSendReply)
                .accessibilityLabel("Send reply")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
        .background(UndrmndPrototypeTheme.paper)
    }

    private func postReply(proxy: ScrollViewProxy) {
        let t = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        let me = "you"
        extraReplies.append(
            ThreadReply(
                id: UUID(),
                authorHandle: "@\(me)",
                body: t,
                timeLabel: "just now"
            )
        )
        draft = ""
        replyFieldFocused = false
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo("threadBottom", anchor: .bottom)
        }
    }

    @ViewBuilder
    private func contentCardBlock(_ ref: ThreadContentItemRef, isLink: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ref.title)
                .font(AppFont.subheadlineEmphasis)
            Text(ref.hook)
                .font(AppFont.caption)
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
            Text("· @\(ref.contributedBy)")
                .font(AppFont.caption2)
                .foregroundStyle(UndrmndPrototypeTheme.muted)
            if isLink {
                HStack(spacing: 4) {
                    Text("Open full card")
                    Image(systemName: "chevron.right")
                        .font(AppFont.caption2)
                }
                .font(AppFont.captionEmphasis)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(UndrmndPrototypeTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
        )
    }

    private func forumReplyRow(_ r: ThreadReply) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(UndrmndPrototypeTheme.divider)
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(r.authorHandle)
                        .font(AppFont.captionEmphasis)
                    Spacer()
                    Text(r.timeLabel)
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
}
