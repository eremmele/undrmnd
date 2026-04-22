import SwiftUI

/// Canvas-style, pinch-and-pan view of the path graph. Modal sheet, not a push.
struct PathMapView: View {
    let pathMap: PathMap
    let currentId: UUID?
    let visited: Set<UUID>
    var onSelectNode: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private var layout: PathMapLayout { PathMapLayout(map: pathMap) }

    private let grid: CGFloat = 44

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                ZStack {
                    Canvas { context, _ in
                        for e in pathMap.edges {
                            guard let a = layout.position(for: e.fromNodeId),
                                let b = layout.position(for: e.toNodeId) else { continue }
                            let p1 = CGPoint(
                                x: center.x + CGFloat(a.x) * grid,
                                y: center.y + CGFloat(a.y) * grid
                            )
                            let p2 = CGPoint(
                                x: center.x + CGFloat(b.x) * grid,
                                y: center.y + CGFloat(b.y) * grid
                            )
                            var path = Path()
                            path.move(to: p1)
                            path.addLine(to: p2)
                            context.stroke(
                                path,
                                with: .color(UndrmndPrototypeTheme.divider),
                                lineWidth: 1
                            )
                        }
                    }
                    .allowsHitTesting(false)

                    ForEach(pathMap.edges, id: \.self) { e in
                        if let a = layout.position(for: e.fromNodeId),
                            let b = layout.position(for: e.toNodeId),
                            let lab = e.choiceLabel, !lab.isEmpty {
                            let p1 = CGPoint(
                                x: center.x + CGFloat(a.x) * grid,
                                y: center.y + CGFloat(a.y) * grid
                            )
                            let p2 = CGPoint(
                                x: center.x + CGFloat(b.x) * grid,
                                y: center.y + CGFloat(b.y) * grid
                            )
                            let mid = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
                            Text(lab)
                                .font(AppFont.mapLabel(approxSize: 8, mapWeight: .regular))
                                .foregroundStyle(UndrmndPrototypeTheme.muted)
                                .position(mid)
                        }
                    }
                    ForEach(pathMap.nodes, id: \.id) { n in
                        if let p = layout.position(for: n.id) {
                            let pt = CGPoint(
                                x: center.x + CGFloat(p.x) * grid,
                                y: center.y + CGFloat(p.y) * grid
                            )
                            nodeButton(n, at: pt)
                        }
                    }
                }
                .scaleEffect(scale, anchor: .center)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { v in
                            let next = lastScale * v.magnification
                            scale = min(max(0.5, next), 3)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { g in
                            offset = CGSize(
                                width: lastOffset.width + g.translation.width,
                                height: lastOffset.height + g.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
            }
            .background(UndrmndPrototypeTheme.paper)
            .navigationTitleBrand("Map")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .undrmndShellCtaTextStyle()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func nodeButton(_ n: PathNode, at pt: CGPoint) -> some View {
        let isCurrent = n.id == currentId
        let isVis = visited.contains(n.id)
        let label = shortLabel(n)
        Button {
            onSelectNode(n.id)
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    if n.nodeType == .branch {
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(UndrmndPrototypeTheme.accent, lineWidth: isCurrent ? 2 : 1)
                            .background(
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isVis ? UndrmndPrototypeTheme.accent.opacity(0.12) : Color.clear)
                            )
                            .frame(width: 20, height: 20)
                            .rotationEffect(.degrees(45))
                    } else {
                        Circle()
                            .strokeBorder(UndrmndPrototypeTheme.accent, lineWidth: isCurrent ? 2.5 : 1)
                            .background(Circle().fill(isVis ? UndrmndPrototypeTheme.accent.opacity(0.15) : Color.clear))
                            .frame(width: 20, height: 20)
                    }
                }
                Text(label)
                    .font(AppFont.mapLabel(approxSize: 8, mapWeight: .regular))
                    .foregroundStyle(UndrmndPrototypeTheme.muted)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(label), \(accessibilityNodeKind(n)), \(isCurrent ? "current" : (isVis ? "visited" : "unvisited"))"
            )
        }
        .buttonStyle(.plain)
        .position(pt)
    }

    private func shortLabel(_ n: PathNode) -> String {
        if let t = n.content?.title, !t.isEmpty {
            return String(t.prefix(18)) + (t.count > 18 ? "…" : "")
        }
        if let p = n.branchPrompt, !p.isEmpty {
            return String(p.prefix(18)) + (p.count > 18 ? "…" : "")
        }
        return n.nodeType == .endpoint ? "End" : "·"
    }

    private func accessibilityNodeKind(_ n: PathNode) -> String {
        switch n.nodeType {
        case .card: return "card"
        case .branch: return "branch"
        case .endpoint: return "end"
        }
    }
}
