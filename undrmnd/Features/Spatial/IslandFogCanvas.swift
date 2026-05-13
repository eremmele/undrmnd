import SwiftUI
#if DEBUG
import OSLog
#endif

// #region agent log
#if DEBUG
private enum FogAgentDebug {
    private static let ingest = URL(string: "http://127.0.0.1:7296/ingest/9e54ab7e-7909-4428-be69-12d7b431c558")!
    private static let osLog = Logger(subsystem: "com.undrmnd", category: "debug49c459")
    /// TimelineView redraws frequently; throttle so ingest + Console stay usable.
    private static var lastEmitMono: UInt64 = 0

    static func islandFogBranch(
        _ branch: String,
        hypothesisId: String,
        size: CGSize,
        portalHFrac: CGFloat,
        portalRect: CGRect,
        thumb: Bool,
        strataCount: Int
    ) {
        let now = DispatchTime.now().uptimeNanoseconds
        if now &- FogAgentDebug.lastEmitMono < 500_000_000 { return }
        FogAgentDebug.lastEmitMono = now

        let payload: [String: Any] = [
            "sessionId": "49c459",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "location": "IslandFogCanvas.body",
            "message": branch,
            "hypothesisId": hypothesisId,
            "data": [
                "w": Double(size.width),
                "h": Double(size.height),
                "portalHFrac": Double(portalHFrac),
                "portalX": Double(portalRect.origin.x),
                "portalY": Double(portalRect.origin.y),
                "portalW": Double(portalRect.width),
                "portalHt": Double(portalRect.height),
                "thumbAnchoredReveal": thumb,
                "strataCount": strataCount,
            ]
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        if let jsonLine = String(data: body, encoding: .utf8) {
            // H-console-fallback / H-ATS: always visible if HTTP ingest blocked (filter “debug49c459”).
            FogAgentDebug.osLog.notice("NDJSON ingest+console \(jsonLine, privacy: .public)")
            // H-simulator-persist: host can read via `simctl get_app_container booted data` → Documents/debug-49c459.ndjson
            appendDocumentsNDJSONLine(jsonLine)
        }
        var req = URLRequest(url: ingest)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("49c459", forHTTPHeaderField: "X-Debug-Session-Id")
        req.httpBody = body
        URLSession.shared.dataTask(with: req) { _, response, error in
            if let error {
                FogAgentDebug.osLog.error("ingest transport error hypothesisId=H-ATS \(String(describing: error), privacy: .public)")
            } else if let http = response as? HTTPURLResponse {
                FogAgentDebug.osLog.notice("ingest http status=\(http.statusCode)")
            }
        }.resume()
    }

    /// Pullable from Simulator host without Cursor ingest wiring.
    private static func appendDocumentsNDJSONLine(_ line: String) {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = docs.appendingPathComponent("debug-49c459.ndjson", isDirectory: false)
        guard let chunk = (line + "\n").data(using: .utf8) else { return }
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                let h = try FileHandle(forWritingTo: url)
                defer { try? h.close() }
                try h.seekToEnd()
                try h.write(contentsOf: chunk)
            } else {
                try chunk.write(to: url, options: .atomic)
            }
        } catch {
            FogAgentDebug.osLog.error("documents NDJSON append failed hypothesisId=H-doc-write \(error.localizedDescription, privacy: .public)")
        }
    }
}
#endif
// #endregion

/// Fog-of-war: fog is blur + chunky halftone under a **thumb-anchored portal** (rounded search-card shape),
/// not typography. Drifting stipples add motion; clearer ground rises from the lower third Perplexity-style.
struct IslandFogCanvas: View {
    struct ContainerRevealConfig: Equatable {
        var widthFraction: CGFloat = 0.87
        var aspectTweak: CGFloat = 1
        var cornerRadius: CGFloat = 22
        var bottomBias: CGFloat = 0.055
        var shoulderBlend: CGFloat = 0.16
    }

    enum RevealShapeMode: Equatable {
        case containerSilhouette(config: ContainerRevealConfig)
        case radial
    }

    var revealBand: CGFloat = 0.36
    var cornerRadius: CGFloat = 0
    var revealShapeMode: RevealShapeMode = .containerSilhouette(config: .init())
    /// Choose-beginning screen: fullscreen fog behind the thumb search stack.
    var thumbAnchoredReveal: Bool = false
    /// 0…1 — grows how far the carve reaches **up** while the user types (shape stays a rounded card column).
    var searchPortalBoost: CGFloat = 0
    let strata: [Strata]
    var onStrataTap: ((UUID) -> Void)?
    var strataTapFilter: ((Strata) -> Bool)? = nil

    private let paperTop = Color(red: 244 / 255, green: 241 / 255, blue: 232 / 255)
    private let paperBottom = Color(red: 232 / 255, green: 227 / 255, blue: 216 / 255)
    private let fogDark = Color(red: 54 / 255, green: 52 / 255, blue: 48 / 255).opacity(0.72)
    private let fogMid = Color(red: 78 / 255, green: 75 / 255, blue: 69 / 255).opacity(0.44)
    private let ink = Color(red: 42 / 255, green: 41 / 255, blue: 37 / 255)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 22.0)) { timeline in
            GeometryReader { geo in
                portalScene(for: geo.size, at: timeline.date)
            }
        }
    }

    private func portalScene(for size: CGSize, at date: Date) -> some View {
        let t = date.timeIntervalSinceReferenceDate
        let drift = CGPoint(
            x: sin(t * 0.55) * 1.15 + cos(t * 0.31) * 0.7,
            y: cos(t * 0.48) * 1.05 + sin(t * 0.72) * 0.65
        )
        let portalH = portalHeightFraction(for: size)
        #if DEBUG
        let logRect = debugPortalBounds(for: size, portalHeightFrac: portalH)
        FogAgentDebug.islandFogBranch(
            debugFogBranchLabel(),
            hypothesisId: "H-mask-portal-geometry",
            size: size,
            portalHFrac: portalH,
            portalRect: logRect,
            thumb: thumbAnchoredReveal,
            strataCount: strata.count
        )
        #endif

        return fogLayerStack(size: size, portalH: portalH, drift: drift)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(clipStrokeOverlay())
    }

    #if DEBUG
    private func debugPortalBounds(for size: CGSize, portalHeightFrac portalH: CGFloat) -> CGRect {
        if case let .containerSilhouette(cfg) = revealShapeMode {
            portalFrame(for: size, heightFrac: portalH, config: cfg)
        } else {
            portalFrame(for: size, heightFrac: portalH, config: .init())
        }
    }

    private func debugFogBranchLabel() -> String {
        if strata.isEmpty, thumbAnchoredReveal { return "chooseScreenFogPortal" }
        if strata.isEmpty { return "denseFogFallback" }
        return "libraryMapFogPortal"
    }
    #endif

    @ViewBuilder
    private func fogLayerStack(size: CGSize, portalH: CGFloat, drift: CGPoint) -> some View {
        ZStack {
            LinearGradient(colors: [paperTop, paperBottom], startPoint: .top, endPoint: .bottom)

            if strata.isEmpty, thumbAnchoredReveal {
                chooseScreenFogPortal(size: size, portalHeightFrac: portalH, drift: drift)
            } else if !strata.isEmpty {
                libraryMapFogPortal(size: size, portalHeightFrac: portalH, drift: drift)
            } else {
                denseFogFallback(size: size, drift: drift)
            }
        }
    }

    private func clipStrokeOverlay() -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                UndrmndPrototypeTheme.divider.opacity(cornerRadius > 0 ? 0.65 : 0),
                lineWidth: cornerRadius > 0 ? 1 : 0
            )
    }

    // MARK: - Portal sizing

    /// Single vertical carve: proportions of **device height**, anchored at bottom (rounded “search column”).
    private func portalHeightFraction(for size: CGSize) -> CGFloat {
        /// Match real thumb stack (~title + panel + caption), not a short band; shorter portals made `destinationOut` + blur swallow most fog.
        if thumbAnchoredReveal {
            return min(0.6, 0.4 + CGFloat(searchPortalBoost) * 0.16)
        }
        return min(0.73, 0.36 + revealBand * 0.26 + 0.08)
    }

    /// Tighter punch on choose screen: large `destinationOut` blur was eating most of the mask, leaving fog only at the top.
    private func fingerprintOuterPortalBlur(for thumb: Bool) -> CGFloat {
        thumb ? 5 : 10
    }

    private func fingerprintInnerPortalBlur(for thumb: Bool) -> CGFloat {
        thumb ? 4 : 7
    }

    // MARK: Choose screen (no strata)

    private func chooseScreenFogPortal(size: CGSize, portalHeightFrac: CGFloat, drift: CGPoint) -> some View {
        let outerMask = invertedBottomPortalMask(size: size, portalHeightFrac: portalHeightFrac)
        return ZStack {
            fogMultiplyAnchoredLow(size: size)
                .mask(outerMask)
            lcdHalftoneLayer(size: size, drift: drift)
                .mask(outerMask)
            stippleLayer(size: size, step: 5, alpha: 0.2, drift: drift)
                .mask(outerMask)
            heavyStippleLayer(size: size, drift: drift)
                .mask(outerMask)
            fineStippleLayer(size: size, drift: drift)
                .mask(outerMask)
            portalRimGlow(size: size, portalHeightFrac: portalHeightFrac, intensity: 0.52)
                .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
    }

    // MARK: Library map (strata + fog)

    private func libraryMapFogPortal(size: CGSize, portalHeightFrac: CGFloat, drift: CGPoint) -> some View {
        let nodes = strataLayout(width: size.width, height: size.height)
        let outerFog = invertedBottomPortalMask(size: size, portalHeightFrac: portalHeightFrac)
        let innerClear = bottomPortalInteriorMask(size: size, portalHeightFrac: portalHeightFrac)

        return ZStack {
            nodes
                .drawingGroup(opaque: false)
                .blur(radius: 15)
                .modifier(BlockyRasterPixellate(pixelApprox: 5.2))
                .overlay {
                    Rectangle()
                        .fill(.thinMaterial.opacity(0.56))
                        .mask(outerFog)
                        .blendMode(.plusLighter)
                }
                .mask(outerFog)
                .allowsHitTesting(false)

            fogMultiplyAnchoredLow(size: size)
                .mask(outerFog)

            lcdHalftoneLayer(size: size, drift: drift)
                .mask(outerFog)

            stippleLayer(size: size, step: 5, alpha: 0.17, drift: drift)
                .mask(outerFog)

            heavyStippleLayer(size: size, drift: drift)
                .mask(outerFog)

            fineStippleLayer(size: size, drift: drift)
                .mask(outerFog)

            nodes
                .mask(innerClear)

            portalRimGlow(size: size, portalHeightFrac: portalHeightFrac, intensity: 0.56)
                .allowsHitTesting(false)
        }
    }

    private func denseFogFallback(size: CGSize, drift: CGPoint) -> some View {
        ZStack {
            fogMultiplyAnchoredLow(size: size)
            lcdHalftoneLayer(size: size, drift: drift)
            stippleLayer(size: size, step: 5, alpha: 0.18, drift: drift)
            heavyStippleLayer(size: size, drift: drift)
            fineStippleLayer(size: size, drift: drift)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func revealShapeBlur(size: CGSize, portalHeightFrac: CGFloat, blur: CGFloat) -> some View {
        switch revealShapeMode {
        case let .containerSilhouette(config):
            let rect = portalFrame(for: size, heightFrac: portalHeightFrac, config: config)
            let corner = max(14, min(32, config.cornerRadius))
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.white)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)

                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.78))
                    .frame(
                        width: rect.width * (0.58 + config.shoulderBlend),
                        height: max(52, rect.height * 0.2)
                    )
                    .position(
                        x: rect.midX,
                        y: rect.minY + max(34, rect.height * 0.12)
                    )
            }
            .blur(radius: blur)

        case .radial:
            let rect = portalFrame(for: size, heightFrac: portalHeightFrac, config: .init(widthFraction: 0.74, aspectTweak: 1, cornerRadius: 999, bottomBias: 0.08, shoulderBlend: 0))
            Circle()
                .fill(Color.white)
                .frame(width: min(rect.width, rect.height), height: min(rect.width, rect.height))
                .blur(radius: blur)
                .position(x: rect.midX, y: rect.midY)
        }
    }

    /// White where fog/occlusion renders; punched-out soft portal anchored at bottom (`destinationOut`).
    private func invertedBottomPortalMask(size: CGSize, portalHeightFrac: CGFloat) -> some View {
        ZStack {
            Color.white
                .frame(width: size.width, height: size.height)
            revealShapeBlur(size: size, portalHeightFrac: portalHeightFrac, blur: fingerprintOuterPortalBlur(for: thumbAnchoredReveal))
                .blendMode(.destinationOut)
        }
        .frame(width: size.width, height: size.height)
        .compositingGroup()
    }

    /// White inside portal (readable island), soot outside.
    private func bottomPortalInteriorMask(size: CGSize, portalHeightFrac: CGFloat) -> some View {
        ZStack {
            Color.black
                .frame(width: size.width, height: size.height)
            revealShapeBlur(size: size, portalHeightFrac: portalHeightFrac, blur: fingerprintInnerPortalBlur(for: thumbAnchoredReveal))
        }
        .frame(width: size.width, height: size.height)
        .compositingGroup()
    }

    /// Soft light along the carved edge (warm “opening”, not typography-shaped).
    private func portalRimGlow(size: CGSize, portalHeightFrac: CGFloat, intensity: CGFloat) -> some View {
        let config: ContainerRevealConfig
        if case let .containerSilhouette(c) = revealShapeMode {
            config = c
        } else {
            config = .init(widthFraction: 0.74, aspectTweak: 1, cornerRadius: 999, bottomBias: 0.08, shoulderBlend: 0)
        }
        let rect = portalFrame(for: size, heightFrac: portalHeightFrac, config: config)
        let r = max(14, min(32, config.cornerRadius))
        return RoundedRectangle(cornerRadius: r, style: .continuous)
            .stroke(Color.white.opacity(intensity * 0.34), lineWidth: 5)
            .blur(radius: 10)
            .frame(width: rect.width + 10, height: rect.height + 16)
            .position(x: rect.midX, y: rect.midY)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }

    private func portalFrame(for size: CGSize, heightFrac: CGFloat, config: ContainerRevealConfig) -> CGRect {
        let tweak = min(1.1, max(0.9, config.aspectTweak))
        let w = min(size.width * 0.92, size.width * config.widthFraction * tweak)
        let heightCompensation = 1 + ((1 - tweak) * 0.14)
        let h = max(140, size.height * heightFrac * heightCompensation)
        let insetBottom = size.height * config.bottomBias
        let x = (size.width - w) / 2
        let y = size.height - insetBottom - h
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// Darken upper field / corners; complements bottom carve.
    private func fogMultiplyAnchoredLow(size: CGSize) -> some View {
        ZStack {
            RadialGradient(
                stops: [
                    .init(color: fogDark.opacity(0.92), location: 0),
                    .init(color: fogMid.opacity(0.55), location: 0.35),
                    .init(color: Color.clear, location: 0.62),
                ],
                center: UnitPoint(x: 0.52, y: 0.05),
                startRadius: 8,
                endRadius: min(size.width, size.height) * 0.94
            )
            RadialGradient(
                stops: [
                    .init(color: fogDark.opacity(0.55), location: 0),
                    .init(color: Color.clear, location: 1),
                ],
                center: UnitPoint(x: 0.5, y: 0.92),
                startRadius: 24,
                endRadius: min(size.width, size.height) * 0.92
            )
        }
        .compositingGroup()
        .blendMode(.multiply)
    }

    // MARK: Strata layout (weighted into the upward portal)

    private func strataLayout(width: CGFloat, height: CGFloat) -> some View {
        let positions: [CGPoint] = [
            CGPoint(x: width * 0.51, y: height * 0.42),
            CGPoint(x: width * 0.33, y: height * 0.50),
            CGPoint(x: width * 0.66, y: height * 0.54),
            CGPoint(x: width * 0.43, y: height * 0.62),
            CGPoint(x: width * 0.78, y: height * 0.66),
        ]
        return ZStack(alignment: .topLeading) {
            if strata.count >= 2 {
                connectorLine(from: CGPoint(x: width * 0.26, y: height * 0.44), to: CGPoint(x: width * 0.43, y: height * 0.51))
                connectorLine(from: CGPoint(x: width * 0.44, y: height * 0.56), to: CGPoint(x: width * 0.61, y: height * 0.59))
            }
            ForEach(Array(strata.enumerated()), id: \.element.id) { index, item in
                if index < positions.count {
                    strataNode(strata: item, width: width)
                        .position(positions[index])
                }
            }
        }
    }

    @ViewBuilder
    private func strataNode(strata: Strata, width: CGFloat) -> some View {
        let cardW = widthCard(indexRole: strata.mapVisibility, width: width)
        let dimmed = strata.mapVisibility != .revealed
        let obscured = strata.mapVisibility == .obscured
        let scale = strataCardScale(strata.mapVisibility)
        let canTap =
            !obscured &&
            onStrataTap != nil &&
            (strataTapFilter?(strata) ?? true)

        Group {
            if canTap, let onStrataTap {
                Button {
                    onStrataTap(strata.id)
                } label: {
                    strataCard(strata: strata, width: cardW, dimmed: dimmed)
                }
                .buttonStyle(.plain)
            } else {
                strataCard(strata: strata, width: cardW, dimmed: dimmed)
                    .opacity(obscured ? 0.38 : 1)
            }
        }
        .scaleEffect(scale, anchor: .center)
    }

    private func strataCardScale(_ v: StrataMapVisibility) -> CGFloat {
        switch v {
        case .revealed: return 1
        case .partial: return 0.94
        case .obscured: return 0.88
        }
    }

    private func widthCard(indexRole: StrataMapVisibility, width: CGFloat) -> CGFloat {
        switch indexRole {
        case .revealed: return min(202, width * 0.46)
        case .partial: return min(164, width * 0.38)
        case .obscured: return min(152, width * 0.35)
        }
    }

    private func strataCard(strata: Strata, width: CGFloat, dimmed: Bool) -> some View {
        Text(strata.title)
            .font(AppFont.subheadlineEmphasis)
            .foregroundStyle(ink.opacity(dimmed ? 0.62 : 0.96))
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
            .padding(12)
            .frame(width: width, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(dimmed ? 0.2 : 0.36))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(ink.opacity(dimmed ? 0.1 : 0.18), lineWidth: 1)
            )
    }

    private func connectorLine(from: CGPoint, to: CGPoint) -> some View {
        Path { p in
            p.move(to: from)
            p.addLine(to: to)
        }
        .stroke(ink.opacity(0.17), style: StrokeStyle(lineWidth: 0.85, dash: [4, 4]))
    }

    private func lcdHalftoneLayer(size: CGSize, drift: CGPoint) -> some View {
        Canvas { context, canvasSize in
            let matrix: [[CGFloat]] = [
                [0, 8, 2, 10],
                [12, 4, 14, 6],
                [3, 11, 1, 9],
                [15, 7, 13, 5],
            ]
            let step: CGFloat = 6
            let cols = Int(canvasSize.width / step) + 2
            let rows = Int(canvasSize.height / step) + 2
            for r in 0 ..< rows {
                for c in 0 ..< cols {
                    let threshold = matrix[r % 4][c % 4] / 15
                    let x = CGFloat(c) * step + drift.x * 0.55
                    let y = CGFloat(r) * step + drift.y * 0.45
                    let opacity = 0.035 + threshold * 0.055
                    let rect = CGRect(x: x, y: y, width: 2.1, height: 2.1)
                    context.fill(Path { p in p.addRect(rect) }, with: .color(ink.opacity(opacity)))
                }
            }

            for y in stride(from: CGFloat(0), through: canvasSize.height, by: 5) {
                let rect = CGRect(x: 0, y: y + drift.y * 0.18, width: canvasSize.width, height: 0.45)
                context.fill(Path { p in p.addRect(rect) }, with: .color(Color.black.opacity(0.028)))
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func heavyStippleLayer(size: CGSize, drift: CGPoint) -> some View {
        Canvas { context, canvasSize in
            let step: CGFloat = 4
            let cols = Int(canvasSize.width / step) + 1
            let rows = Int(canvasSize.height / step) + 1
            for r in 0 ..< rows {
                for c in 0 ..< cols {
                    let x = CGFloat(c) * step + drift.x
                    let y = CGFloat(r) * step + drift.y
                    let rect = CGRect(x: x, y: y, width: 1.35, height: 1.35)
                    context.fill(Path(ellipseIn: rect), with: .color(ink.opacity(0.076)))
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func stippleLayer(size: CGSize, step: CGFloat, alpha: CGFloat, drift: CGPoint) -> some View {
        Canvas { context, canvasSize in
            let cols = Int(canvasSize.width / step) + 1
            let rows = Int(canvasSize.height / step) + 1
            for r in 0 ..< rows {
                for c in 0 ..< cols {
                    let x = CGFloat(c) * step + drift.x * 0.74
                    let y = CGFloat(r) * step + drift.y * 0.66
                    let jitter = CGFloat((c + r * 13) % 7) * 0.35
                    let rect = CGRect(x: x + jitter, y: y, width: 1.28, height: 1.28)
                    context.fill(Path(ellipseIn: rect), with: .color(ink.opacity(alpha)))
                }
            }
            for r in stride(from: 0, to: rows, by: 2) {
                for c in stride(from: 0, to: cols, by: 3) {
                    let x = CGFloat(c) * step + step * 0.5 + drift.x * 0.42
                    let y = CGFloat(r) * step + step * 0.35 + drift.y * 0.44
                    let rect = CGRect(x: x, y: y, width: 1, height: 1)
                    context.fill(Path(ellipseIn: rect), with: .color(Color.black.opacity(0.068)))
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func fineStippleLayer(size: CGSize, drift: CGPoint) -> some View {
        Canvas { context, canvasSize in
            let step: CGFloat = 3
            let cols = Int(canvasSize.width / step) + 1
            let rows = Int(canvasSize.height / step) + 1
            for r in 0 ..< rows {
                for c in 0 ..< cols {
                    let x = CGFloat(c) * step + drift.x * 0.32
                    let y = CGFloat(r) * step - drift.y * 0.26
                    let rect = CGRect(x: x, y: y, width: 0.9, height: 0.9)
                    if (c + r) % 3 != 0 { continue }
                    context.fill(Path { p in p.addRect(rect) }, with: .color(ink.opacity(0.056)))
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Raster / halftone

private struct BlockyRasterPixellate: ViewModifier {
    var pixelApprox: CGFloat

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let s = max(3, min(pixelApprox, min(geo.size.width, geo.size.height) * 0.02))
            content
                .scaleEffect(1 / s)
                .frame(width: geo.size.width / s, height: geo.size.height / s)
                .drawingGroup(opaque: false)
                .scaleEffect(s)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
    }
}

#Preview("Choose fog") {
    IslandFogCanvas(
        revealBand: 0,
        thumbAnchoredReveal: true,
        searchPortalBoost: 0.5,
        strata: []
    )
}

#Preview("Map portal") {
    IslandFogCanvas(
        revealBand: 0.44,
        strata: [
            Strata.mock(title: "Opening thread"),
            Strata.mock(title: "Nearby", visibility: .partial),
        ],
        onStrataTap: { _ in }
    )
}
