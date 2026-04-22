import SwiftUI

/// Comfortable reading rhythm for long body copy (~1.2× line height on book 17pt).
private let cardBodyLineSpacing: CGFloat = 5

struct CardView: View {
    let item: ContentItem
    var nodeByline: String?
    /// Open `source_url` or `action_url` in the in-app Safari sheet (parent owns `SFSafariViewController`).
    /// When `true`, path advances when Safari is dismissed (contribute / read as needed).
    var onRequestSafari: (URL, Bool) -> Void
    var onContinue: () -> Void
    var onOpenContributor: ((String) -> Void)?

    @State private var reflectDraft: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(item.topic.displayName)
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                Spacer(minLength: 0)
            }

            Text(item.title)
                .font(AppFont.cardOrBranchTitle)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.hook)
                .font(AppFont.subheadline)
                .foregroundStyle(UndrmndPrototypeTheme.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if let body = item.body, !body.isEmpty {
                Text(body)
                    .font(AppFont.body)
                    .foregroundStyle(UndrmndPrototypeTheme.primary)
                    .lineSpacing(cardBodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if item.interactionType == .reflect {
                TextField("Optional: one line, stays on this device", text: $reflectDraft, axis: .vertical)
                    .lineLimit(1...3)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(UndrmndPrototypeTheme.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(UndrmndPrototypeTheme.divider, lineWidth: 1)
                    )
                    .font(AppFont.subheadline)
                    .accessibilityLabel("Private reflection, not sent to the server")
            }

            VStack(alignment: .leading, spacing: 10) {
                primaryBlock

                if showsContinue {
                    continueButton
                }
            }

            if let cite = item.sourceCitation, !cite.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    if let u = item.sourceUrl.flatMap({ URL(string: $0) }) {
                        Link(cite, destination: u)
                            .font(AppFont.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    } else {
                        Text(cite)
                            .font(AppFont.caption)
                            .foregroundStyle(UndrmndPrototypeTheme.secondary)
                    }
                }
            }

            bylineView
        }
    }

    private var showsContinue: Bool {
        switch item.interactionType {
        case .read, .contribute, .observe:
            return true
        case .reflect:
            return false
        }
    }

    @ViewBuilder
    private var primaryBlock: some View {
        let type = item.interactionType
        let act = item.actionUrl.flatMap { URL(string: $0) }
        let src = item.sourceUrl.flatMap { URL(string: $0) }
        switch type {
        case .read:
            if act != nil || src != nil {
                Button {
                    if let a = act { onRequestSafari(a, false) } else if let s = src { onRequestSafari(s, false) }
                } label: {
                    Text("Read the source.")
                }
                .buttonStyle(LargeProminentPathButtonStyle())
                .accessibilityLabel("Read the source in Safari")
            }
        case .reflect:
            Button {
                onContinue()
            } label: {
                Text("I sat with it.")
            }
            .buttonStyle(LargeProminentPathButtonStyle())
            .accessibilityLabel("I sat with it.")
        case .observe:
            if let a = act {
                Button {
                    onRequestSafari(a, false)
                } label: {
                    Text("I noticed.")
                }
                .buttonStyle(LargeProminentPathButtonStyle())
            } else {
                Button { onContinue() } label: { Text("I noticed.") }
                    .buttonStyle(LargeProminentPathButtonStyle())
            }
        case .contribute:
            if let a = act {
                Button { onRequestSafari(a, true) } label: { Text("Explore") }
                    .buttonStyle(LargeProminentPathButtonStyle())
            } else if let s = src {
                Button {
                    #if DEBUG
                    print("warning: contribute card missing action_url; using source_url")
                    #endif
                    onRequestSafari(s, true)
                } label: { Text("Explore") }
                .buttonStyle(LargeProminentPathButtonStyle())
            } else {
                Button { onContinue() } label: { Text("Explore") }
                    .buttonStyle(LargeProminentPathButtonStyle())
                    .disabled(true)
                    .accessibilityLabel("Contribute handoff link missing")
            }
        }
    }

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Continue")
                .font(.system(.body, design: .default))
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(UndrmndPrototypeTheme.divider.opacity(0.45), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(UndrmndPrototypeTheme.accent)
        .accessibilityLabel("Continue on this path")
    }

    @ViewBuilder
    private var bylineView: some View {
        let handle = (nodeByline ?? item.contributedBy).map { s -> String in
            s.hasPrefix("@") ? String(s.dropFirst()) : s
        }
        if let h = handle, !h.isEmpty {
            Button {
                onOpenContributor?(h)
            } label: {
                Text("contributed by @\(h)")
                    .font(AppFont.caption2)
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
            }
            .buttonStyle(.plain)
            .disabled(onOpenContributor == nil)
            .accessibilityLabel("Contributed by \(h). Double tap to open profile.")
        }
    }
}

struct LargeProminentPathButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.bodySemibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(UndrmndPrototypeTheme.accent)
            .foregroundStyle(UndrmndPrototypeTheme.paper)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
