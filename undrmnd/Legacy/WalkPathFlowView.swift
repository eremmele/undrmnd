import SwiftUI
import UIKit

// DEPRECATED: see v2-artifacts/undrmnd_content_rubric_v2.md. Use `Views/Path/PathView`.

/// Linear path experience ported from the web flow’s `LA` screen (spark → nugget → branch → … → destination).
struct WalkPathFlowView: View {
    let path: WalkPath
    var onDestinationAction: (String, WalkPath) -> Void
    var onClosing: (WalkPath) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    @State private var stepIndex: Int = 0
    @State private var selectedBranchID: String?
    @State private var showCompassRose: Bool = false
    @State private var expandedNuggetID: String?
    @State private var marginNoteDraft: String = ""
    @State private var marginNoteEditingID: String?
    @State private var marginNotes: [String: String] = [:]
    @State private var contributeDraft: String = ""

    private var visibleNodes: ArraySlice<WalkPathNode> {
        let end = min(stepIndex + 1, path.nodes.count)
        return path.nodes[0..<end]
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    breadcrumb
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    ForEach(Array(visibleNodes.enumerated()), id: \.element.id) { index, node in
                        nodeView(node, index: index, isLastVisible: index == visibleNodes.count - 1)
                            .padding(.horizontal, 16)
                            .id(node.id)
                    }
                }
                .padding(.vertical, 16)
            }
            .onChange(of: stepIndex) { _, _ in
                guard let last = visibleNodes.last else { return }
                scrollBottom(proxy: proxy, to: last.id)
            }
        }
        .background(UndrmndPrototypeTheme.paper)
        .navigationTitleBrand(path.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
                    .tint(UndrmndPrototypeTheme.secondary)
                    .accessibilityLabel("Close path")
            }
        }
    }

    private var breadcrumb: some View {
        let crumbs = visibleNodes.enumerated().compactMap { index, node -> String? in
            switch node {
            case .spark:
                return "Start"
            case .branch(_, let title, _, let branches):
                if let sid = selectedBranchID, let match = branches.first(where: { $0.id == sid }) {
                    return match.label
                }
                let prefix = String(title.prefix(16))
                return prefix + (title.count > 16 ? "…" : "")
            case .destination:
                return "Arrived"
            case .nugget, .community, .contribute:
                let title = nodeTitle(node) ?? "·"
                if title == "·" { return nil }
                let prefix = String(title.prefix(16))
                return prefix + (title.count > 16 ? "…" : "")
            }
        }
        return HStack(spacing: 6) {
            ForEach(Array(crumbs.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(AppFont.caption2Medium)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                Image(systemName: "chevron.right")
                    .font(AppFont.caption2Emphasis)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Path progress: " + crumbs.joined(separator: ", "))
    }

    @ViewBuilder
    private func nodeView(_ node: WalkPathNode, index: Int, isLastVisible: Bool) -> some View {
        switch node {
        case .spark(_, let title, let content, let footprints, let handoff):
            sparkBlock(title: title, content: content, footprints: footprints, handoff: handoff, showContinue: isLastVisible)

        case .nugget(let id, let title, let content, let source):
            nuggetBlock(id: id, title: title, content: content, source: source, showContinue: isLastVisible)

        case .branch(_, let title, let compassRose, let branches):
            branchBlock(title: title, compassRose: compassRose, branches: branches)

        case .community(_, let title, let content):
            communityBlock(title: title, content: content, showContinue: isLastVisible)

        case .contribute(_, let title, let content):
            contributeBlock(title: title, content: content)

        case .destination(_, let title, let content, let actions):
            destinationBlock(title: title, content: content, actions: actions)
        }
    }

    private func nodeTitle(_ node: WalkPathNode) -> String? {
        switch node {
        case .nugget(_, let title, _, _),
             .community(_, let title, _),
             .contribute(_, let title, _):
            return title
        default:
            return nil
        }
    }

    // MARK: - Spark

    private func sparkBlock(
        title: String,
        content: String,
        footprints: Int?,
        handoff: WalkHandoff?,
        showContinue: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let footprints {
                HStack(spacing: 5) {
                    Image(systemName: "shoeprints.fill")
                        .font(AppFont.caption2)
                    Text("\(footprints) people have walked this path")
                        .font(AppFont.caption2)
                }
                .foregroundStyle(UndrmndPrototypeTheme.muted)
                .accessibilityLabel("\(footprints) people have walked this path")
            }

            if let handoff {
                VStack(alignment: .leading, spacing: 4) {
                    Text("“\(handoff.text)”")
                        .font(AppFont.caption)
                        .italic()
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    Text("From \(handoff.user), who walked this path before you")
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(UndrmndPrototypeTheme.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(UndrmndPrototypeTheme.muted, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SPARK")
                    .font(AppFont.mapLabel(approxSize: 9, mapWeight: .semibold))
                    .tracking(0.06)
                    .foregroundStyle(UndrmndPrototypeTheme.paper)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(UndrmndPrototypeTheme.primary)

                if let guide = path.guide {
                    Text("\(guide.name) completed this path \(guide.completed)")
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }

                Text(title)
                    .font(AppFont.subheadlineEmphasis)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(content)
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(UndrmndPrototypeTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
            )

            if showContinue {
                continueButton { advance() }
            }
        }
        .padding(.bottom, 10)
    }

    // MARK: - Nugget

    private func nuggetBlock(
        id: String,
        title: String,
        content: String,
        source: String?,
        showContinue: Bool
    ) -> some View {
        let expanded = expandedNuggetID == id
        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(title)
                            .font(AppFont.subheadlineEmphasis)
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        if marginNotes[id] != nil {
                            Image(systemName: "pencil.line")
                                .font(AppFont.caption2)
                                .foregroundStyle(UndrmndPrototypeTheme.muted)
                                .accessibilityHidden(true)
                        }
                    }

                    Text(content)
                        .font(AppFont.caption)
                        .foregroundStyle(UndrmndPrototypeTheme.secondary)
                        .lineLimit(expanded ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)

                    if let source {
                        Text("\(source) · \(expanded ? "Show less" : "Read more")")
                            .font(AppFont.caption2)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withOptionalAnimation {
                        expandedNuggetID = expanded ? nil : id
                    }
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Nugget: \(title)")
                .accessibilityHint(expanded ? "Collapses summary" : "Expands full text")

                if expanded {
                    Divider().overlay(UndrmndPrototypeTheme.divider)

                    if marginNoteEditingID == id {
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Your annotation…", text: $marginNoteDraft, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                                .font(AppFont.caption)

                            HStack(spacing: 8) {
                                Button("Save note") {
                                    marginNotes[id] = marginNoteDraft
                                    marginNoteEditingID = nil
                                    marginNoteDraft = ""
                                }
                                .font(AppFont.caption)
                                .buttonStyle(.bordered)

                                Button("Cancel") {
                                    marginNoteEditingID = nil
                                    marginNoteDraft = ""
                                }
                                .font(AppFont.caption)
                                .foregroundStyle(UndrmndPrototypeTheme.muted)
                            }
                        }
                    } else if let note = marginNotes[id] {
                        Text("Your note: “\(note)”")
                            .font(AppFont.caption)
                            .italic()
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    } else {
                        Button {
                            marginNoteEditingID = id
                            marginNoteDraft = marginNotes[id] ?? ""
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil.line")
                                    .font(AppFont.caption2)
                                Text("Write in the margin")
                                    .font(AppFont.caption)
                            }
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(UndrmndPrototypeTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
            )

            if showContinue {
                continueButton { advance() }
            }
        }
        .padding(.bottom, 10)
    }

    // MARK: - Branch

    private func branchBlock(
        title: String,
        compassRose: String?,
        branches: [WalkBranchOption]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Rectangle()
                .fill(UndrmndPrototypeTheme.divider)
                .frame(height: 1)
                .padding(.vertical, 4)

            if (compassRose?.isEmpty == false), !showCompassRose, selectedBranchID == nil {
                Button {
                    withOptionalAnimation { showCompassRose = true }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "safari")
                            .font(AppFont.caption2)
                        Text("A question before you choose…")
                            .font(AppFont.caption)
                    }
                    .italic()
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                }
                .accessibilityLabel("Show reflective question before choosing")
            }

            if showCompassRose, let compassRose {
                VStack(alignment: .leading, spacing: 6) {
                    Text(compassRose)
                        .font(AppFont.caption)
                        .italic()
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("No right answer. Just something to carry with you.")
                        .font(AppFont.caption2)
                        .foregroundStyle(UndrmndPrototypeTheme.muted)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(UndrmndPrototypeTheme.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(UndrmndPrototypeTheme.secondary, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            }

            Text(title)
                .font(AppFont.captionEmphasis)
                .foregroundStyle(UndrmndPrototypeTheme.primary)

            FlowPillStack(
                branches: branches,
                selectedID: selectedBranchID,
                onSelect: { id in
                    guard selectedBranchID == nil else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withOptionalAnimation {
                        selectedBranchID = id
                        showCompassRose = false
                    }
                    advance()
                }
            )

            if selectedBranchID == nil {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(branches) { b in
                        Text("\(b.label): \(b.preview)")
                            .font(AppFont.caption2)
                            .foregroundStyle(UndrmndPrototypeTheme.muted)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.bottom, 10)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Community

    private func communityBlock(title: String, content: String, showContinue: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                onDestinationAction("campfire", path)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(AppFont.caption)
                    Text("\(title): \(content)")
                        .font(AppFont.caption)
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(UndrmndPrototypeTheme.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(UndrmndPrototypeTheme.muted, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title). \(content). Opens campfire.")

            if showContinue {
                continueButton { advance() }
            }
        }
        .padding(.bottom, 10)
    }

    // MARK: - Contribute

    private func contributeBlock(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.captionEmphasis)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
            Text(content)
                .font(AppFont.caption)
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextField("A resource, an experience, a counterpoint…", text: $contributeDraft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .font(AppFont.caption)

            HStack(spacing: 8) {
                Button("Share") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    advance()
                }
                .font(AppFont.caption)
                .buttonStyle(.bordered)
                .disabled(contributeDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Skip") {
                    advance()
                }
                .font(AppFont.caption)
                .foregroundStyle(UndrmndPrototypeTheme.muted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UndrmndPrototypeTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
        )
        .padding(.bottom, 10)
    }

    // MARK: - Destination

    private func destinationBlock(title: String, content: String, actions: [WalkDestinationAction]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(UndrmndPrototypeTheme.divider)
                .frame(height: 1)
                .padding(.vertical, 4)

            VStack(spacing: 4) {
                Text("You've reached the end of this branch.")
                    .font(AppFont.caption2)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
                Text("What would you like to do?")
                    .font(AppFont.title3)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(content)
                .font(AppFont.caption)
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    Button {
                        handleDestination(action.action)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: action.iconName)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                                )
                            Text(action.label)
                                .font(AppFont.subheadline)
                                .foregroundStyle(UndrmndPrototypeTheme.primary)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(action.label)

                    if index < actions.count - 1 {
                        Divider().overlay(UndrmndPrototypeTheme.divider)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            .background(UndrmndPrototypeTheme.panel)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
            )
        }
        .padding(.bottom, 10)
    }

    private func continueButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("Continue")
                    .undrmndShellCtaTextStyle()
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(UndrmndPrototypeTheme.accent)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .accessibilityLabel("Continue to next step")
    }

    private func advance() {
        guard stepIndex < path.nodes.count - 1 else { return }
        withOptionalAnimation {
            stepIndex += 1
        }
    }

    private func handleDestination(_ action: String) {
        switch action {
        case "save", "later", "handoff":
            dismiss()
            onClosing(path)
        case "entry":
            dismiss()
            onDestinationAction(action, path)
        default:
            dismiss()
            onDestinationAction(action, path)
        }
    }

    private func scrollBottom(proxy: ScrollViewProxy, to id: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withOptionalAnimation {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }

    private func withOptionalAnimation(_ body: () -> Void) {
        if reduceMotion {
            body()
        } else {
            withAnimation(.easeOut(duration: 0.35)) {
                body()
            }
        }
    }
}

// MARK: - Branch pills

private struct FlowPillStack: View {
    let branches: [WalkBranchOption]
    let selectedID: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            FlexiblePillRow(branches: branches, selectedID: selectedID, onSelect: onSelect)
        }
    }
}

private struct FlexiblePillRow: View {
    let branches: [WalkBranchOption]
    let selectedID: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(branches) { branch in
                pill(branch)
            }
        }
    }

    private func pill(_ branch: WalkBranchOption) -> some View {
        let lockedIn = selectedID != nil
        let isSelected = selectedID == branch.id
        let muted = lockedIn && !isSelected

        return Button {
            onSelect(branch.id)
        } label: {
            Text(branch.label)
                .font(AppFont.caption2Medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(muted ? UndrmndPrototypeTheme.muted : (isSelected ? UndrmndPrototypeTheme.paper : UndrmndPrototypeTheme.primary))
                .background(isSelected ? UndrmndPrototypeTheme.primary : UndrmndPrototypeTheme.paper)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(
                            muted ? UndrmndPrototypeTheme.muted : UndrmndPrototypeTheme.primary,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(lockedIn)
        .accessibilityLabel(branch.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
