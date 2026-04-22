import SwiftUI

struct BranchView: View {
    let prompt: String
    let compass: String?
    let edges: [PathEdge]
    var onSelect: (PathEdge) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(prompt)
                .font(AppFont.branchPrompt)
                .foregroundStyle(UndrmndPrototypeTheme.primary)
                .fixedSize(horizontal: false, vertical: true)
            if let c = compass, !c.isEmpty {
                Text(c)
                    .font(AppFont.caption)
                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
            }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(edges, id: \.toNodeId) { e in
                    Button {
                        onSelect(e)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(e.choiceLabel ?? "Choose")
                                .font(AppFont.subheadlineEmphasis)
                                .foregroundStyle(UndrmndPrototypeTheme.primary)
                            if let p = e.choicePreview, !p.isEmpty {
                                Text(p)
                                    .font(AppFont.caption)
                                    .foregroundStyle(UndrmndPrototypeTheme.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
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
                    .accessibilityLabel("\(e.choiceLabel ?? "Choice"). \(e.choicePreview ?? "")")
                }
            }
        }
    }
}
