import SwiftUI

/// Path-specific graph on the same **instrument map** shell as Explore **Your Map**: fixed sketch canvas (`260×300`), centered with spacers, bottom summary pill — only the graphic + footer reflect path data.
struct PathMapView: View {
    let pathMap: PathMap
    let currentId: UUID?
    let visited: Set<UUID>
    var onSelectNode: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    /// Pan/zoom so floated tags and expanded layout stay reachable without crowding.
    @State private var mapScaleGesture: CGFloat = 1
    @State private var mapScaleLastEnd: CGFloat = 1
    @State private var mapPan: CGSize = .zero
    @State private var mapPanLast: CGSize = .zero

    private var layout: PathMapLayout { PathMapLayout(map: pathMap) }

    /// Core sketch coordinates (Territory parity); bleed inset gives labels room beyond the graph bbox.
    private static let canvasW: CGFloat = 260
    private static let canvasH: CGFloat = 300
    private static let margin: CGFloat = 18
    private static let contentBleed: CGFloat = 88
    private static var layoutSurfaceW: CGFloat { canvasW + contentBleed * 2 }
    private static var layoutSurfaceH: CGFloat { canvasH + contentBleed * 2 }
    /// Matches `TerritoryMapViteGraphic` base scale before user pinch.
    private static let graphScale: CGFloat = 1.35
    private static let mapScaleClamp: ClosedRange<CGFloat> = 0.55 ... 2.85

    private struct LayoutMetric {
        let cell: CGFloat
        let origin: CGPoint
    }

    /// Estimated tag footprint for overlap passes (radii ~= enclosing circle of text + padding).
    private static let tagCharsPerVisualLine = 13
    private static let tagEstCharWidth: CGFloat = 5.1
    private static let tagEstLineHeight: CGFloat = 12
    private static let tagInterClearance: CGFloat = 10
    private static let edgeVsNodeClearance: CGFloat = 8

    var body: some View {
        NavigationStack {
            ZStack {
                InstrumentMapChrome.canvas
                    .ignoresSafeArea()
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        VStack {
                            Spacer(minLength: 0)
                            pathMapGraphic
                                .frame(maxWidth: .infinity)
                                .frame(maxHeight: max(360, geo.size.height * 0.72))
                            Spacer(minLength: 0)
                        }
                        pathFooter
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(InstrumentMapChrome.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Map")
                        .font(AppFont.brandWordmark)
                        .foregroundStyle(InstrumentMapChrome.inkSoft.opacity(0.95))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(.body, design: .default))
                            .fontWeight(.semibold)
                            .foregroundStyle(InstrumentMapChrome.inkSoft.opacity(0.9))
                    }
                    .accessibilityLabel("Dismiss map")
                }
            }
        }
        .instrumentMapColorSchemeIsolation()
    }

    private var pathFooter: some View {
        let title = pathMap.path?.title ?? "Path"
        let visitedN = visited.count
        let totalN = pathMap.nodes.count
        return VStack(spacing: 6) {
            Text(title)
                .font(AppFont.captionEmphasis)
                .foregroundStyle(InstrumentMapChrome.inkSoft.opacity(0.95))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.88)
            Text("\(visitedN) visited · \(totalN) \(totalN == 1 ? "stop" : "stops")")
                .font(AppFont.caption2)
                .foregroundStyle(InstrumentMapChrome.footerCaption)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .strokeBorder(InstrumentMapChrome.gridLine.opacity(0.55), lineWidth: 0.5)
        )
    }

    /// Same sketch as `TerritoryMapViteGraphic`, with bleed inset + surfaced coordinates for floated tags.
    @ViewBuilder
    private var pathMapGraphic: some View {
        if let metric = layoutMetric() {
            let rawNodePts = nodeCanvasPoints(metric: metric)
            let nodePts = rawNodePts.mapValues { surfaceShift($0) }
            let nodeTitles = Dictionary(uniqueKeysWithValues: pathMap.nodes.map { ($0.id, mappedTitleForMap($0)) })
            let labelPts = floatedNodeLabelPositions(nodePts: nodePts, nodeTitles: nodeTitles, metric: metric)
            let edgeItems = finalizedEdgeLayouts(
                metric: metric,
                nodeLabelCenters: labelPts,
                nodeTitles: nodeTitles
            )

            let effectiveScale = Self.graphScale * mapScaleGesture

            ZStack {
                Canvas { context, _ in
                    for e in pathMap.edges {
                        guard let a = layout.position(for: e.fromNodeId),
                              let b = layout.position(for: e.toNodeId) else { continue }
                        let p1 = surfaceShift(point(for: a, metric: metric))
                        let p2 = surfaceShift(point(for: b, metric: metric))
                        var path = Path()
                        path.move(to: p1)
                        path.addLine(to: p2)
                        context.stroke(
                            path,
                            with: .color(InstrumentMapChrome.gridLine),
                            lineWidth: 1
                        )
                    }
                }
                .allowsHitTesting(false)

                Canvas { context, _ in
                    let leaderColor = InstrumentMapChrome.gridLine.opacity(0.55)
                    for n in pathMap.nodes {
                        guard let pt = nodePts[n.id],
                              let lb = labelPts[n.id] else { continue }
                        var v = CGPoint(x: lb.x - pt.x, y: lb.y - pt.y)
                        let len = hypot(v.x, v.y)
                        guard len > 6 else { continue }
                        v.x /= len
                        v.y /= len
                        let shorten: CGFloat = 20
                        let end = CGPoint(x: lb.x - v.x * shorten, y: lb.y - v.y * shorten)
                        var path = Path()
                        path.move(to: pt)
                        path.addLine(to: end)
                        context.stroke(path, with: .color(leaderColor), style: StrokeStyle(lineWidth: 0.85, dash: [3.5, 3]))
                    }
                }
                .allowsHitTesting(false)
                .zIndex(2)

                ForEach(edgeItems, id: \.id) { item in
                    InstrumentMapEdgeLabelChip(text: item.label)
                        .position(item.anchor)
                        .zIndex(4)
                        .allowsHitTesting(false)
                }

                ForEach(pathMap.nodes, id: \.id) { n in
                    if let pt = nodePts[n.id],
                       let lbl = labelPts[n.id] {
                        floatedNodeChrome(n: n, markerPt: pt, titlePt: lbl)
                    }
                }
            }
            .frame(width: Self.layoutSurfaceW, height: Self.layoutSurfaceH)
            .scaleEffect(effectiveScale, anchor: .center)
            .offset(mapPan)
            .contentShape(Rectangle())
            .simultaneousGesture(
                MagnifyGesture()
                    .onChanged { v in
                        let next = mapScaleLastEnd * v.magnification
                        mapScaleGesture = min(max(Self.mapScaleClamp.lowerBound, next), Self.mapScaleClamp.upperBound)
                    }
                    .onEnded { _ in
                        mapScaleLastEnd = mapScaleGesture
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { g in
                        mapPan = CGSize(
                            width: mapPanLast.width + g.translation.width,
                            height: mapPanLast.height + g.translation.height
                        )
                    }
                    .onEnded { _ in
                        mapPanLast = mapPan
                    }
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Path layout map. Pinch to zoom and drag to pan. Tap a node to open it.")
        } else {
            Text("Nothing to draw on this map yet.")
                .font(AppFont.captionEmphasis)
                .foregroundStyle(InstrumentMapChrome.footerCaption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .scaleEffect(Self.graphScale)
        }
    }

    private func layoutMetric() -> LayoutMetric? {
        var tuples: [(x: Int, y: Int)] = []
        tuples.reserveCapacity(pathMap.nodes.count)
        for n in pathMap.nodes {
            guard let p = layout.position(for: n.id) else { continue }
            tuples.append((p.x, p.y))
        }
        guard !tuples.isEmpty else { return nil }
        let xs = tuples.map(\.x)
        let ys = tuples.map(\.y)
        let minX = xs.min()!
        let maxX = xs.max()!
        let minY = ys.min()!
        let maxY = ys.max()!
        let spanX = max(1, maxX - minX)
        let spanY = max(1, maxY - minY)
        let innerW = Self.canvasW - Self.margin * 2
        let innerH = Self.canvasH - Self.margin * 2
        let cell = min(innerW / CGFloat(spanX), innerH / CGFloat(spanY))
        let contentW = CGFloat(spanX) * cell
        let contentH = CGFloat(spanY) * cell
        let originX = (Self.canvasW - contentW) / 2 - CGFloat(minX) * cell
        let originY = (Self.canvasH - contentH) / 2 - CGFloat(minY) * cell
        return LayoutMetric(cell: cell, origin: CGPoint(x: originX, y: originY))
    }

    private func point(for p: PathMapLayout.Position, metric: LayoutMetric) -> CGPoint {
        CGPoint(
            x: metric.origin.x + CGFloat(p.x) * metric.cell,
            y: metric.origin.y + CGFloat(p.y) * metric.cell
        )
    }

    private func surfaceShift(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x + Self.contentBleed, y: p.y + Self.contentBleed)
    }

    private struct EdgeChipLayoutItem: Identifiable {
        let id: String
        let label: String
        var anchor: CGPoint
    }

    private func nodeCanvasPoints(metric: LayoutMetric) -> [UUID: CGPoint] {
        var out: [UUID: CGPoint] = [:]
        for n in pathMap.nodes {
            guard let p = layout.position(for: n.id) else { continue }
            out[n.id] = point(for: p, metric: metric)
        }
        return out
    }

    private func centroid(of pts: [CGPoint]) -> CGPoint {
        guard !pts.isEmpty else {
            return CGPoint(x: Self.layoutSurfaceW / 2, y: Self.layoutSurfaceH / 2)
        }
        let sx = pts.reduce(CGFloat.zero) { $0 + $1.x }
        let sy = pts.reduce(CGFloat.zero) { $0 + $1.y }
        let n = CGFloat(pts.count)
        return CGPoint(x: sx / n, y: sy / n)
    }

    /// Stable mix for jitter (not security-sensitive). `Hasher.finalize()` yields `Int` on current SDKs.
    private func layoutMix(_ id: UUID) -> Int {
        var h = Hasher()
        h.combine(id.uuidString)
        return h.finalize()
    }

    private static func estimatedTagCollisionRadius(for text: String) -> CGFloat {
        let mpc = Self.tagCharsPerVisualLine
        let lineCount = max(1, min(2, Int(ceil(Double(text.count) / Double(mpc)))))
        let charCount = min(text.count, lineCount * mpc)
        let textW = CGFloat(charCount) * Self.tagEstCharWidth
        let cappedW = min(textW + 16, CGFloat(mpc * lineCount) * Self.tagEstCharWidth + 16)
        let h = CGFloat(lineCount) * Self.tagEstLineHeight + 16
        return hypot(cappedW, h) / 2
    }

    private static func estimatedEdgeChipCollisionRadius(for text: String) -> CGFloat {
        let mpc = 11
        let lineCount = max(1, min(2, Int(ceil(Double(text.count) / Double(mpc)))))
        let charCount = min(text.count, lineCount * mpc)
        let textW = CGFloat(charCount) * 4.95
        let w = min(textW + 16, 112)
        let h = CGFloat(lineCount) * 11 + 10
        return hypot(w, h) / 2
    }

    private func relaxDiscCrowding(positions: inout [CGPoint], radii: [CGFloat], gap: CGFloat, iterations: Int) {
        guard positions.count > 1, positions.count == radii.count else { return }
        for _ in 0..<iterations {
            for i in positions.indices {
                for j in (i + 1) ..< positions.count {
                    var pa = positions[i]
                    var pb = positions[j]
                    var dx = pb.x - pa.x
                    var dy = pb.y - pa.y
                    var d = hypot(dx, dy)
                    let ri = radii[i]
                    let rj = radii[j]
                    let minD = ri + rj + gap
                    if d < 0.001 {
                        dx = 0.35
                        dy = -0.24
                        d = hypot(dx, dy)
                    }
                    if d >= minD { continue }
                    let push = (minD - d) * 0.5
                    let ux = dx / d
                    let uy = dy / d
                    pa.x -= ux * push
                    pa.y -= uy * push
                    pb.x += ux * push
                    pb.y += uy * push
                    positions[i] = pa
                    positions[j] = pb
                }
            }
        }
    }

    private func relaxNodeLabelCollisions(
        _ labels: inout [UUID: CGPoint],
        titles: [UUID: String],
        gap: CGFloat,
        iterations: Int
    ) {
        let ids = Array(labels.keys)
        guard ids.count > 1 else { return }
        for _ in 0..<iterations {
            for i in ids.indices {
                for j in (i + 1) ..< ids.count {
                    let a = ids[i]
                    let b = ids[j]
                    guard var pa = labels[a], var pb = labels[b] else { continue }
                    let ra = Self.estimatedTagCollisionRadius(for: titles[a] ?? "")
                    let rb = Self.estimatedTagCollisionRadius(for: titles[b] ?? "")
                    var dx = pb.x - pa.x
                    var dy = pb.y - pa.y
                    var d = hypot(dx, dy)
                    let minD = ra + rb + gap
                    if d < 0.001 {
                        dx = 0.38
                        dy = -0.22
                        d = hypot(dx, dy)
                    }
                    if d >= minD { continue }
                    let push = (minD - d) * 0.5
                    let ux = dx / d
                    let uy = dy / d
                    pa.x -= ux * push
                    pa.y -= uy * push
                    pb.x += ux * push
                    pb.y += uy * push
                    labels[a] = pa
                    labels[b] = pb
                }
            }
        }
    }

    private func repelEdgeAnchorsFromNodeTags(
        edgeItems: inout [EdgeChipLayoutItem],
        nodeLabelCenters: [UUID: CGPoint],
        nodeTitles: [UUID: String]
    ) {
        for i in edgeItems.indices {
            var p = edgeItems[i].anchor
            let rE = Self.estimatedEdgeChipCollisionRadius(for: edgeItems[i].label)
            for (nid, center) in nodeLabelCenters {
                guard let t = nodeTitles[nid] else { continue }
                let rN = Self.estimatedTagCollisionRadius(for: t)
                var dx = p.x - center.x
                var dy = p.y - center.y
                var d = hypot(dx, dy)
                let need = rE + rN + Self.edgeVsNodeClearance
                if d < 0.001 {
                    p.x += need * 0.4
                    continue
                }
                if d < need {
                    let push = need - d
                    dx /= d
                    dy /= d
                    p.x += dx * push
                    p.y += dy * push
                }
            }
            p.x = min(max(22, p.x), Self.layoutSurfaceW - 22)
            p.y = min(max(20, p.y), Self.layoutSurfaceH - 20)
            edgeItems[i].anchor = p
        }
    }

    private func edgeChipLayoutsInitial(metric: LayoutMetric) -> [EdgeChipLayoutItem] {
        var items: [EdgeChipLayoutItem] = []
        for e in pathMap.edges {
            guard let lab = e.choiceLabel, !lab.isEmpty,
                  let a = layout.position(for: e.fromNodeId),
                  let b = layout.position(for: e.toNodeId) else { continue }
            let p1 = surfaceShift(point(for: a, metric: metric))
            let p2 = surfaceShift(point(for: b, metric: metric))
            let outset = max(16, metric.cell * 0.44)
            let anchor = perpendicularLabelAnchor(from: p1, to: p2, outset: outset)
            items.append(
                EdgeChipLayoutItem(
                    id: "\(e.fromNodeId.uuidString)-\(e.toNodeId.uuidString)-\(e.orderIndex)",
                    label: lab,
                    anchor: anchor
                )
            )
        }
        guard items.count > 1 else { return items }
        var anchors = items.map(\.anchor)
        let radii = items.map { Self.estimatedEdgeChipCollisionRadius(for: $0.label) }
        relaxDiscCrowding(positions: &anchors, radii: radii, gap: Self.tagInterClearance, iterations: 18)
        for i in items.indices {
            var p = anchors[i]
            p.x = min(max(22, p.x), Self.layoutSurfaceW - 22)
            p.y = min(max(20, p.y), Self.layoutSurfaceH - 20)
            items[i].anchor = p
        }
        return items
    }

    private func floatedNodeLabelPositions(
        nodePts: [UUID: CGPoint],
        nodeTitles: [UUID: String],
        metric: LayoutMetric
    ) -> [UUID: CGPoint] {
        let ids = Array(nodePts.keys)
        guard !ids.isEmpty else { return [:] }
        let c = centroid(of: ids.compactMap { nodePts[$0] })
        let radial = max(44, metric.cell * 0.58)

        var labels: [UUID: CGPoint] = [:]
        for nid in ids {
            guard let pt = nodePts[nid] else { continue }
            var d = CGPoint(x: pt.x - c.x, y: pt.y - c.y)
            let len = hypot(d.x, d.y)
            if len < 1 {
                let slot = CGFloat(abs(layoutMix(nid)) % 500) / 500 * 2 * .pi
                d = CGPoint(x: cos(slot), y: sin(slot))
            } else {
                d = CGPoint(x: d.x / len, y: d.y / len)
            }
            let perp = CGPoint(x: -d.y, y: d.x)
            let stagger = CGFloat((abs(layoutMix(nid)) % 11) - 5) * 3.4
            labels[nid] = CGPoint(
                x: pt.x + d.x * radial + perp.x * stagger,
                y: pt.y + d.y * radial + perp.y * stagger
            )
        }

        relaxNodeLabelCollisions(&labels, titles: nodeTitles, gap: Self.tagInterClearance, iterations: 26)

        let clampPad: CGFloat = 72
        for nid in ids {
            guard var p = labels[nid] else { continue }
            p.x = min(max(clampPad, p.x), Self.layoutSurfaceW - clampPad)
            p.y = min(max(clampPad, p.y), Self.layoutSurfaceH - clampPad)
            labels[nid] = p
        }

        let tetherDist = max(300, metric.cell * 7.5)
        tetherNodeLabels(&labels, nodePts: nodePts, maxDist: tetherDist)
        relaxNodeLabelCollisions(&labels, titles: nodeTitles, gap: Self.tagInterClearance, iterations: 14)
        return labels
    }

    private func tetherNodeLabels(_ labels: inout [UUID: CGPoint], nodePts: [UUID: CGPoint], maxDist: CGFloat) {
        for (id, pt) in nodePts {
            guard var lb = labels[id] else { continue }
            var v = CGPoint(x: lb.x - pt.x, y: lb.y - pt.y)
            let len = hypot(v.x, v.y)
            if len > maxDist {
                v.x /= len
                v.y /= len
                lb = CGPoint(x: pt.x + v.x * maxDist, y: pt.y + v.y * maxDist)
                labels[id] = lb
            }
        }
    }

    private func finalizedEdgeLayouts(
        metric: LayoutMetric,
        nodeLabelCenters: [UUID: CGPoint],
        nodeTitles: [UUID: String]
    ) -> [EdgeChipLayoutItem] {
        var items = edgeChipLayoutsInitial(metric: metric)
        repelEdgeAnchorsFromNodeTags(edgeItems: &items, nodeLabelCenters: nodeLabelCenters, nodeTitles: nodeTitles)
        return items
    }
    private func perpendicularLabelAnchor(from p1: CGPoint, to p2: CGPoint, outset: CGFloat) -> CGPoint {
        let mx = (p1.x + p2.x) / 2
        let my = (p1.y + p2.y) / 2
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let len = hypot(dx, dy)
        guard len > 1 else {
            return CGPoint(x: mx, y: my - outset)
        }
        let nx = -dy / len * outset
        let ny = dx / len * outset
        return CGPoint(x: mx + nx, y: my + ny)
    }

    @ViewBuilder
    private func floatedNodeChrome(n: PathNode, markerPt: CGPoint, titlePt: CGPoint) -> some View {
        let isCurrent = n.id == currentId
        let isVis = visited.contains(n.id)
        let title = mappedTitleForMap(n)
        let ax = accessibilityLabel(for: n, label: title, isCurrent: isCurrent, visited: isVis)

        Group {
            Button {
                onSelectNode(n.id)
            } label: {
                markerChrome(n: n, isCurrent: isCurrent, isVis: isVis)
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .position(markerPt)
            .accessibilityLabel(ax)

            Button {
                onSelectNode(n.id)
            } label: {
                InstrumentMapNodeTitleTag(text: title)
            }
            .buttonStyle(.plain)
            .position(titlePt)
            .accessibilityHidden(true)
            .allowsHitTesting(true)
        }
        .zIndex(isCurrent ? 20 : 14)
    }

    @ViewBuilder
    private func markerChrome(n: PathNode, isCurrent: Bool, isVis: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if isCurrent {
                    InstrumentMapBeaconView()
                        .frame(width: 44, height: 44)
                }
                if n.nodeType == .branch {
                    RoundedRectangle(cornerRadius: 2)
                        .strokeBorder(InstrumentMapChrome.nodeOutline, lineWidth: isCurrent ? 2 : 1)
                        .background(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isVis ? InstrumentMapChrome.nodeFillVisited : Color.clear)
                        )
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(45))
                } else {
                    Circle()
                        .strokeBorder(InstrumentMapChrome.nodeOutline, lineWidth: isCurrent ? 2.25 : 1)
                        .background(
                            Circle()
                                .fill(isVis ? InstrumentMapChrome.nodeFillVisited : Color.clear)
                        )
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: 48, height: 28)

            if isCurrent {
                Text("You are here")
                    .font(AppFont.mapLabel(approxSize: 7.8, mapWeight: .semibold))
                    .foregroundStyle(InstrumentMapChrome.beaconCore.opacity(0.95))
                    .textCase(.uppercase)
                    .tracking(0.55)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .fixedSize()
            }
        }
    }

    private func accessibilityLabel(for n: PathNode, label: String, isCurrent: Bool, visited: Bool) -> String {
        let here = isCurrent ? "You are here. " : ""
        return "\(here)\(label), \(accessibilityNodeKind(n)), \(isCurrent ? "current step" : (visited ? "visited" : "unvisited"))"
    }

    /// Longer readable title for floated tags (~2 lines in `InstrumentMapNodeTitleTag`).
    private func mappedTitleForMap(_ n: PathNode) -> String {
        let maxChars = 56
        if let t = n.content?.title, !t.isEmpty {
            guard t.count > maxChars else { return t }
            return String(t.prefix(maxChars)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
        }
        if let p = n.branchPrompt, !p.isEmpty {
            guard p.count > maxChars else { return p }
            return String(p.prefix(maxChars)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
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
