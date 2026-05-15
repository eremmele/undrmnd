import SwiftUI

// MARK: - Explore path ↔ site parameters

/// Binds first-run onboarding to the same tunables `undrmnd-site/script.js` uses for the “How it works” map
/// (`scrollProgress` → reveal radius; drift vs pointer for the fog clearing center).
enum FogMapExplorePath: Equatable {
    /// Steps 01–02 on the site: map without your island yet — radius grows as the curiosity deepens
    /// (analog of `scrollProgress` while the canvas approaches center of the viewport).
    case curiosityEntry(typingRevealProgress: CGFloat)
    /// Step 03: Strata cluster + optional wider reveal after first contribution (`expandedFogReveal`).
    case firstIsland(strata: [Strata], wideRevealFromContribution: Bool)
}

// MARK: - Layout model (mirrors script.js node records)

private enum FogMapNodeID: Hashable {
    case strata(UUID)
    case decorative(Int)
}

private struct FogMapNodeModel: Identifiable {
    let id: FogMapNodeID
    let position: CGPoint
    let radius: CGFloat
    let label: String
    let cluster: Int
    let ghost: Bool
    /// When non-nil, this dot is a Strata the app can route into.
    let strataId: UUID?
    let mapVisibility: StrataMapVisibility?
}

// MARK: - Seeded PRNG (same LCG as `seedRandom` in script.js)

private struct FogMapSeededRandom {
    private var state: Int

    init(seed: Int) {
        state = seed
    }

    mutating func nextUnit() -> CGFloat {
        state = (state * 9301 + 49297) % 233_280
        return CGFloat(state) / 233_280
    }
}

// MARK: - Layout engine

private enum LearningCommonsFogMapLayout {
    private static let decorativeLabels: [String] = [
        "Lichen recolonisation", "Tide pools", "Folk indicators of air quality",
        "Sourdough microbiomes", "Subway ecologies", "Estuarine birdsong",
        "Glacial striations", "Dyer's woad", "Clay weathering",
        "Foxing in old paper", "Heat-island moss", "Salt marsh decline",
        "Bone china clay", "Wind-fallen apples", "Roman road alignment",
        "Dialect of fog", "Slow-moving rivers", "Verge wildflowers",
        "Quiet aircraft routes", "Mended walls", "Frost cracks",
        "Backyard astronomy", "Rooftop lichens", "Field hedgerows",
    ]

    static func nodes(for path: FogMapExplorePath, size: CGSize) -> [FogMapNodeModel] {
        switch path {
        case .curiosityEntry:
            return decorativeField(size: size, seed: 7)
        case let .firstIsland(strata, _):
            return strataIsland(size: size, strata: strata)
        }
    }

    /// `script.js` `buildNodes` — three clusters + ghost sprinkles.
    private static func decorativeField(size: CGSize, seed: Int) -> [FogMapNodeModel] {
        var rng = FogMapSeededRandom(seed: seed)
        let w = size.width
        let h = size.height
        var nodes: [FogMapNodeModel] = []
        let clusters: [(cx: CGFloat, cy: CGFloat, r: CGFloat, count: Int)] = [
            (w * 0.32, h * 0.46, w * 0.18, 8),
            (w * 0.65, h * 0.36, w * 0.14, 6),
            (w * 0.55, h * 0.72, w * 0.16, 7),
        ]
        var idx = 0
        for (ci, c) in clusters.enumerated() {
            for k in 0 ..< c.count {
                let ang = rng.nextUnit() * .pi * 2
                let dist = sqrt(rng.nextUnit()) * c.r
                let x = c.cx + cos(ang) * dist
                let y = c.cy + sin(ang) * dist
                let r = 2 + rng.nextUnit() * 3
                nodes.append(
                    FogMapNodeModel(
                        id: .decorative(ci * 100 + k),
                        position: CGPoint(x: x, y: y),
                        radius: r,
                        label: decorativeLabels[idx % decorativeLabels.count],
                        cluster: ci,
                        ghost: false,
                        strataId: nil,
                        mapVisibility: nil
                    )
                )
                idx += 1
            }
        }
        for k in 0 ..< 14 {
            nodes.append(
                FogMapNodeModel(
                    id: .decorative(300 + k),
                    position: CGPoint(x: rng.nextUnit() * w, y: rng.nextUnit() * h),
                    radius: 1.2 + rng.nextUnit() * 1.2,
                    label: decorativeLabels[idx % decorativeLabels.count],
                    cluster: -1,
                    ghost: true,
                    strataId: nil,
                    mapVisibility: nil
                )
            )
            idx += 1
        }
        return nodes
    }

    private static func strataIsland(size: CGSize, strata: [Strata]) -> [FogMapNodeModel] {
        guard !strata.isEmpty else { return decorativeField(size: size, seed: 11) }
        let seed = Int(strata[0].id.uuidString.hashValue & 0x7FFF_FFFF)
        var rng = FogMapSeededRandom(seed: max(1, seed))
        let w = size.width
        let h = size.height
        let center = CGPoint(x: w * 0.5, y: h * 0.48)
        let spread = min(w, h) * 0.13
        var nodes: [FogMapNodeModel] = []
        let count = strata.count
        let primaryIndex = strata.firstIndex { $0.mapVisibility == .revealed } ?? 0
        for (i, s) in strata.enumerated() {
            let baseAngle = -CGFloat.pi / 2 + CGFloat(i) / CGFloat(max(count, 1)) * 2 * .pi
            let jitterR = spread * (0.82 + rng.nextUnit() * 0.28)
            let ox = cos(baseAngle) * jitterR
            let oy = sin(baseAngle) * jitterR
            let ghostLike = s.mapVisibility == .obscured
            let baseR: CGFloat = ghostLike ? 1.4 + rng.nextUnit() * 1.2 : 2.2 + rng.nextUnit() * 2.8
            let isPrimary = i == primaryIndex && !ghostLike
            let r = isPrimary ? baseR * 1.85 : baseR
            let shortTitle = s.title.count > 34 ? String(s.title.prefix(31)) + "…" : s.title
            nodes.append(
                FogMapNodeModel(
                    id: .strata(s.id),
                    position: CGPoint(x: center.x + ox, y: center.y + oy),
                    radius: r,
                    label: shortTitle,
                    cluster: 0,
                    ghost: ghostLike,
                    strataId: s.id,
                    mapVisibility: s.mapVisibility
                )
            )
        }
        for k in 0 ..< 10 {
            nodes.append(
                FogMapNodeModel(
                    id: .decorative(500 + k),
                    position: CGPoint(x: rng.nextUnit() * w, y: rng.nextUnit() * h),
                    radius: 1.1 + rng.nextUnit() * 1.1,
                    label: decorativeLabels[Int(rng.nextUnit() * 100) % decorativeLabels.count],
                    cluster: -1,
                    ghost: true,
                    strataId: nil,
                    mapVisibility: nil
                )
            )
        }
        return nodes
    }
}

// MARK: - View

/// Canvas translation of `undrmnd-site/script.js` “How it works” fog map: grid, clustered nodes,
/// same-cluster edges near the reveal center, radial darkening, drift vs touch.
struct LearningCommonsFogMapView: View {
    var explorePath: FogMapExplorePath
    var onThreadTap: ((UUID) -> Void)?
    /// Pause TimelineView ticks while the user types in a field above the map (keeps keyboard + first responder stable).
    var pauseAnimation: Bool = false
    /// When false, disables the full-screen drag gesture so text fields keep focus and receive input.
    var enablePointerReveal: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pointerActive = false
    @State private var pointerLocation: CGPoint = .zero

    private var timelineInterval: TimeInterval {
        if pauseAnimation { return 3600 }
        return reduceMotion ? 1.0 / 8.0 : 1.0 / 30.0
    }

    /// Charcoal fog canvas — matches ``ExploreFogChrome/nightCanvas`` on the Explore shell.
    static let nightCanvas = Color(red: 22 / 255, green: 20 / 255, blue: 15 / 255)
    private let night = nightCanvas
    private let gridLine = Color(red: 233 / 255, green: 226 / 255, blue: 209 / 255).opacity(0.06)
    private let edgeStroke = Color(red: 233 / 255, green: 226 / 255, blue: 209 / 255).opacity(0.20)
    private let nodeFill = Color(red: 233 / 255, green: 226 / 255, blue: 209 / 255)
    private let ringStroke = Color(red: 196 / 255, green: 178 / 255, blue: 138 / 255)

    var body: some View {
        ZStack {
            night
                .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: timelineInterval)) { timeline in
                GeometryReader { geo in
                    let size = geo.size
                    let nodes = LearningCommonsFogMapLayout.nodes(for: explorePath, size: size)
                    let scrollAnalog = scrollRevealAnalog(for: explorePath)
                    let reveal = revealGeometry(in: size, at: timeline.date, scrollAnalog: scrollAnalog)
                    let layoutScale = min(size.width, size.height) / 390

                    ZStack {
                        night

                        Canvas { context, canvasSize in
                            drawGrid(context: &context, size: canvasSize)
                            drawClusterEdges(
                                context: &context,
                                nodes: nodes,
                                center: reveal.center,
                                baseRadius: reveal.baseRadius,
                                edgeDistanceThreshold: 110 * layoutScale
                            )
                            drawNodes(
                                context: &context,
                                nodes: nodes,
                                center: reveal.center,
                                baseRadius: reveal.baseRadius
                            )
                            drawFogVignette(
                                context: &context,
                                size: canvasSize,
                                center: reveal.center,
                                baseRadius: reveal.baseRadius
                            )
                            drawEdgeBleed(context: &context, size: canvasSize)
                        }
                        .allowsHitTesting(false)

                        tapOverlay(
                            nodes: nodes,
                            center: reveal.center,
                            baseRadius: reveal.baseRadius,
                            onThreadTap: onThreadTap
                        )
                    }
                    .modifier(FogMapPointerRevealGesture(
                        enabled: enablePointerReveal,
                        pointerActive: $pointerActive,
                        pointerLocation: $pointerLocation
                    ))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Library map preview")
        .accessibilityHint("The fog clears around where you touch. Strata appear as you read and contribute.")
    }

    // MARK: Reveal center + radius (script.js `driftT`, `mouse`, `scrollProgress`, `REVEAL_RADIUS`)

    private func scrollRevealAnalog(for path: FogMapExplorePath) -> CGFloat {
        switch path {
        case let .curiosityEntry(p):
            return CGFloat(min(1, max(0, p)))
        case let .firstIsland(_, wide):
            return wide ? 1.0 : 0.42
        }
    }

    private func revealGeometry(in size: CGSize, at date: Date, scrollAnalog: CGFloat) -> (center: CGPoint, baseRadius: CGFloat) {
        let w = size.width
        let h = size.height
        let t = reduceMotion ? 0 : date.timeIntervalSinceReferenceDate

        let driftX = w * (0.5 + cos(t * 0.0035) * 0.22)
        let driftY = h * (0.5 + sin(t * 0.0035 * 0.7) * 0.18)

        let cx: CGFloat
        let cy: CGFloat
        if pointerActive {
            cx = pointerLocation.x
            cy = pointerLocation.y
        } else if case .curiosityEntry = explorePath {
            let thumbBias = CGPoint(x: w * 0.5, y: h * 0.72)
            cx = driftX * 0.55 + thumbBias.x * 0.45
            cy = driftY * 0.55 + thumbBias.y * 0.45
        } else {
            cx = driftX
            cy = driftY
        }

        let minDim = min(w, h)
        let revealRadius = 170 * (minDim / 390)
        let baseRadius = revealRadius + scrollAnalog * 120 * (minDim / 390)
        return (CGPoint(x: cx, y: cy), baseRadius)
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
        let step: CGFloat = 32
        for x in stride(from: CGFloat(0), through: size.width, by: step) {
            var p = Path()
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(p, with: .color(gridLine), style: StrokeStyle(lineWidth: 1))
        }
        for y in stride(from: CGFloat(0), through: size.height, by: step) {
            var p = Path()
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(p, with: .color(gridLine), style: StrokeStyle(lineWidth: 1))
        }
    }

    private func drawClusterEdges(
        context: inout GraphicsContext,
        nodes: [FogMapNodeModel],
        center: CGPoint,
        baseRadius: CGFloat,
        edgeDistanceThreshold: CGFloat
    ) {
        context.blendMode = .normal
        for i in 0 ..< nodes.count {
            for j in (i + 1) ..< nodes.count {
                let a = nodes[i]
                let b = nodes[j]
                if a.cluster == -1 || b.cluster == -1 || a.cluster != b.cluster { continue }
                let dx = a.position.x - b.position.x
                let dy = a.position.y - b.position.y
                let d = hypot(dx, dy)
                if d >= edgeDistanceThreshold { continue }
                let midx = (a.position.x + b.position.x) / 2
                let midy = (a.position.y + b.position.y) / 2
                let dist = hypot(midx - center.x, midy - center.y)
                let alpha = max(0, 1 - dist / (baseRadius * 1.2)) * 0.5
                var p = Path()
                p.move(to: a.position)
                p.addLine(to: b.position)
                context.opacity = alpha
                context.stroke(p, with: .color(edgeStroke), style: StrokeStyle(lineWidth: 0.6))
            }
        }
        context.opacity = 1
    }

    private func drawNodes(
        context: inout GraphicsContext,
        nodes: [FogMapNodeModel],
        center: CGPoint,
        baseRadius: CGFloat
    ) {
        for n in nodes {
            let dist = hypot(n.position.x - center.x, n.position.y - center.y)
            let t = max(0, 1 - dist / max(baseRadius, 1))
            let baseAlpha: CGFloat = n.ghost ? 0.18 : 0.34
            let alpha = baseAlpha + t * (1 - baseAlpha)

            if t > 0.5, !n.ghost {
                let ringRect = CGRect(
                    x: n.position.x - n.radius - 6,
                    y: n.position.y - n.radius - 6,
                    width: (n.radius + 6) * 2,
                    height: (n.radius + 6) * 2
                )
                var ring = Path()
                ring.addEllipse(in: ringRect)
                context.stroke(
                    ring,
                    with: .color(ringStroke.opacity(Double((t - 0.5) * 0.85))),
                    style: StrokeStyle(lineWidth: 0.8)
                )
            }

            let dotRect = CGRect(
                x: n.position.x - n.radius,
                y: n.position.y - n.radius,
                width: n.radius * 2,
                height: n.radius * 2
            )
            var dot = Path()
            dot.addEllipse(in: dotRect)
            context.fill(dot, with: .color(nodeFill.opacity(Double(alpha))))

            if t > 0.55, !n.ghost {
                let labelAlpha = (t - 0.55) / 0.45
                let text = Text(n.label)
                    .font(AppFont.mapLabel(approxSize: 11, mapWeight: .regular))
                    .foregroundStyle(nodeFill.opacity(labelAlpha))
                let resolved = context.resolve(text)
                let pt = CGPoint(x: n.position.x + n.radius + 8, y: n.position.y)
                context.draw(resolved, at: pt, anchor: .leading)
            }
        }
    }

    private func drawFogVignette(
        context: inout GraphicsContext,
        size: CGSize,
        center: CGPoint,
        baseRadius: CGFloat
    ) {
        let rect = CGRect(origin: .zero, size: size)
        let stops: [Gradient.Stop] = [
            .init(color: night.opacity(0), location: 0),
            .init(color: night.opacity(0.55), location: 0.6),
            .init(color: night, location: 1),
        ]
        context.fill(
            Path(rect),
            with: .radialGradient(
                Gradient(stops: stops),
                center: center,
                startRadius: baseRadius * 0.2,
                endRadius: max(baseRadius * 1.4, min(size.width, size.height) * 0.55)
            )
        )
    }

    /// Opaque charcoal at status-bar and home-indicator gutters so the map never reads light at the edges.
    private func drawEdgeBleed(context: inout GraphicsContext, size: CGSize) {
        let bleed = max(72, size.height * 0.14)
        let topRect = CGRect(x: 0, y: 0, width: size.width, height: bleed)
        let bottomRect = CGRect(x: 0, y: size.height - bleed, width: size.width, height: bleed)
        let edgeStops: [Gradient.Stop] = [
            .init(color: night, location: 0),
            .init(color: night.opacity(0.72), location: 0.55),
            .init(color: night.opacity(0), location: 1),
        ]
        context.fill(
            Path(topRect),
            with: .linearGradient(Gradient(stops: edgeStops), startPoint: .zero, endPoint: CGPoint(x: 0, y: bleed))
        )
        context.fill(
            Path(bottomRect),
            with: .linearGradient(
                Gradient(stops: edgeStops),
                startPoint: CGPoint(x: 0, y: size.height),
                endPoint: CGPoint(x: 0, y: size.height - bleed)
            )
        )
    }

    private func tapOverlay(
        nodes: [FogMapNodeModel],
        center: CGPoint,
        baseRadius: CGFloat,
        onThreadTap: ((UUID) -> Void)?
    ) -> some View {
        let eligible = nodes.compactMap { n -> FogMapNodeModel? in
            guard n.strataId != nil, let v = n.mapVisibility else { return nil }
            guard v == .revealed || v == .partial else { return nil }
            let dist = hypot(n.position.x - center.x, n.position.y - center.y)
            let t = max(0, 1 - dist / max(baseRadius, 1))
            return t > 0.48 ? n : nil
        }
        return Group {
            if let onThreadTap {
                ForEach(eligible) { n in
                    Button {
                        onThreadTap(n.strataId!)
                    } label: {
                        Color.clear
                            .frame(width: 48, height: 48)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .position(n.position)
                    .accessibilityLabel("Open thread: \(n.label)")
                    .accessibilityHint("Opens the contributed reading for this dot")
                }
            }
        }
    }
}

// MARK: - Pointer reveal (optional; off while text fields are focused)

private struct FogMapPointerRevealGesture: ViewModifier {
    let enabled: Bool
    @Binding var pointerActive: Bool
    @Binding var pointerLocation: CGPoint

    func body(content: Content) -> some View {
        if enabled {
            content
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            pointerActive = true
                            pointerLocation = value.location
                        }
                        .onEnded { _ in
                            pointerActive = false
                        }
                )
        } else {
            content
        }
    }
}

#Preview("Curiosity entry") {
    LearningCommonsFogMapView(explorePath: .curiosityEntry(typingRevealProgress: 0.55), onThreadTap: nil)
}

#Preview("First island") {
    LearningCommonsFogMapView(
        explorePath: .firstIsland(strata: OnboardingClusterBuilder.cluster(for: "urban lichens"), wideRevealFromContribution: false),
        onThreadTap: { _ in }
    )
}
