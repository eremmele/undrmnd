import SwiftUI

/// Visual tokens from the web prototype (`index.html` / bundled theme object).
enum UndrmndPrototypeTheme {
    static let paper = Color(red: 0.98, green: 0.976, blue: 0.969)
    static let panel = Color(red: 0.957, green: 0.953, blue: 0.945)
    static let divider = Color(red: 0.914, green: 0.910, blue: 0.902)
    /// Desaturated supporting text. Tuned for ≥4.5:1 on `paper` and `panel` (WCAG AA, normal body/caption size).
    static let muted = Color(red: 0.36, green: 0.353, blue: 0.345)
    /// Secondary copy (subheads, de-emphasized body). Slightly stronger than `muted`; still ≥~5:1 on `paper` at typical subhead sizes.
    static let secondary = Color(red: 0.29, green: 0.283, blue: 0.275)
    /// Single ink accent; matches `AccentColor` in Assets (#1A1A19).
    static let accent = Color("AccentColor")
    static let primary = Color("AccentColor")
}

// MARK: - Instrument maps (“Your Map” + path graph sheet)

enum InstrumentMapChrome {
    static let canvas = Color(red: 14 / 255, green: 14 / 255, blue: 16 / 255)
    static let inkSoft = Color(red: 226 / 255, green: 226 / 255, blue: 230 / 255)
    /// Graph edges drawn on charcoal.
    static let gridLine = inkSoft.opacity(0.38)
    /// Near-opaque base under map labels (readable on charcoal canvas).
    static let mapTagFillDeep = Color(red: 12 / 255, green: 12 / 255, blue: 16 / 255).opacity(0.92)
    /// Light veil fused on top of `mapTagFillDeep` — reads like glass on graphite.
    static let mapTagFillVeil = Color.white.opacity(0.1)
    static let mapTagStroke = inkSoft.opacity(0.4)
    static let mapTagText = Color(red: 245 / 255, green: 245 / 255, blue: 248 / 255)
    /// Legacy token; chips use layered deep + veil for contrast (WCAG-minded on charcoal).
    static let edgeChipFill = Color.white.opacity(0.07)
    static let edgeChipStroke = inkSoft.opacity(0.42)
    static let edgeChipText = inkSoft.opacity(0.92)
    static let edgeLabelAmbient = inkSoft.opacity(0.55)
    static let nodeOutline = inkSoft.opacity(0.92)
    static let nodeFillVisited = Color.white.opacity(0.06)
    static let caption = inkSoft.opacity(0.82)
    static let footerCaption = inkSoft.opacity(0.72)
    static let beaconCore = Color(red: 1, green: 0.93, blue: 0.75)
    /// Sketch-map strokes (Territory schematic).
    static let graphAccent = beaconCore.opacity(0.72)
    static let graphSecondary = inkSoft.opacity(0.48)
    static let graphMuted = inkSoft.opacity(0.38)
}

struct InstrumentMapBeaconView: View {
    private let period: Double = 1.85

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate
            let t = CGFloat((elapsed.truncatingRemainder(dividingBy: period)) / period)
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    let stagger = CGFloat(i) / 3
                    let ringPhase = CGFloat((Double(t + stagger)).truncatingRemainder(dividingBy: 1))
                    Circle()
                        .stroke(InstrumentMapChrome.beaconCore.opacity(0.5), lineWidth: 1)
                        .frame(width: 17, height: 17)
                        .scaleEffect(1 + ringPhase * 2.35)
                        .opacity(Double(1 - ringPhase) * 0.76)
                }
                Circle()
                    .fill(InstrumentMapChrome.beaconCore.opacity(0.95))
                    .frame(width: 6.5, height: 6.5)
                    .overlay(
                        Circle()
                            .stroke(InstrumentMapChrome.beaconCore.opacity(0.98), lineWidth: 1)
                            .scaleEffect(1 + 0.1 * CGFloat(sin(Double(t) * Double.pi * 2)))
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

/// Small capsule behind branch choice labels — intrinsic width up to soft max; uniform padding.
struct InstrumentMapEdgeLabelChip: View {
    let text: String

    private let pad: CGFloat = 8

    var body: some View {
        Text(text)
            .font(AppFont.mapLabel(approxSize: 8, mapWeight: .regular))
            .foregroundStyle(InstrumentMapChrome.mapTagText)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 132, alignment: .center)
            .padding(pad)
            .background {
                ZStack {
                    Capsule(style: .continuous)
                        .fill(InstrumentMapChrome.mapTagFillDeep)
                    Capsule(style: .continuous)
                        .fill(InstrumentMapChrome.mapTagFillVeil)
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(InstrumentMapChrome.mapTagStroke.opacity(0.65), lineWidth: 0.5)
            )
    }
}

/// Node title floated off the sketch point; width hugs copy (narrow for short strings like End).
struct InstrumentMapNodeTitleTag: View {
    let text: String

    private let cornerRadius: CGFloat = 8
    private let pad: CGFloat = 8

    var body: some View {
        Text(text)
            .font(AppFont.mapLabel(approxSize: 7.85, mapWeight: .medium))
            .foregroundStyle(InstrumentMapChrome.mapTagText)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 148, alignment: .center)
            .padding(pad)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(InstrumentMapChrome.mapTagFillDeep)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(InstrumentMapChrome.mapTagFillVeil)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(InstrumentMapChrome.mapTagStroke.opacity(0.55), lineWidth: 0.5)
            )
    }
}

// MARK: - Navigation chrome (inline titles match the Explore “undrmnd” bar: MD Lórien headline)

extension View {
    /// Inline navigation bar with **undrmnd** as a small app line and `title` as the screen line (when `showsAppWordmark` is true).
    /// Pass `showsAppWordmark: false` when this view is not inside a visible navigation bar (rare); the bar itself should be hidden separately.
    func navigationTitleBrand(_ title: String, showsAppWordmark: Bool = true) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if showsAppWordmark {
                        VStack(spacing: 2) {
                            Text("undrmnd")
                                .font(AppFont.caption2)
                                .foregroundStyle(UndrmndPrototypeTheme.muted)
                            Text(title)
                                .font(AppFont.brandWordmark)
                                .foregroundStyle(UndrmndPrototypeTheme.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("undrmnd, \(title)")
                    } else {
                        Text(title)
                            .font(AppFont.brandWordmark)
                            .foregroundStyle(UndrmndPrototypeTheme.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            // Explicit paper bar so pushed screens override Explore’s floating / hidden fog chrome.
            .toolbarBackground(UndrmndPrototypeTheme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
    }

    /// Same layout as ``navigationTitleBrand(_:showsAppWordmark:)`` for screens stacked over the Explore fog canvas (hidden bar, warm paper-white ink).
    func navigationTitleBrandFog(_ title: String, showsAppWordmark: Bool = true) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if showsAppWordmark {
                        VStack(spacing: 2) {
                            Text("undrmnd")
                                .font(AppFont.caption2)
                                .foregroundStyle(ExploreFogNavigationInk.muted)
                            Text(title)
                                .font(AppFont.brandWordmark)
                                .foregroundStyle(ExploreFogNavigationInk.title)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("undrmnd, \(title)")
                    } else {
                        Text(title)
                            .font(AppFont.brandWordmark)
                            .foregroundStyle(ExploreFogNavigationInk.title)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

/// Typography on the live fog map (matches ``FogMapShellChrome`` in `ContentView`).
enum ExploreFogNavigationInk {
    static let title = Color(red: 233 / 255, green: 226 / 255, blue: 209 / 255)
    static let secondary = Color(red: 233 / 255, green: 226 / 255, blue: 209 / 255).opacity(0.78)
    static let muted = Color(red: 233 / 255, green: 226 / 255, blue: 209 / 255).opacity(0.52)
}

private struct ExploreUsesFogBackdropKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True when this Explore screen is presented above ``LearningCommonsFogMapView`` (goal clarifier, open-topic session).
    var exploreUsesFogBackdrop: Bool {
        get { self[ExploreUsesFogBackdropKey.self] }
        set { self[ExploreUsesFogBackdropKey.self] = newValue }
    }
}

// MARK: - Shell text CTAs (Done, Mark all read, in-flow Continue on light surfaces)

extension View {
    /// Shared treatment for “Done”, “Mark all read”, and plain “Continue” on light backgrounds.
    func undrmndShellCtaTextStyle() -> some View {
        self
            .font(.system(.body, design: .default))
            .fontWeight(.semibold)
            .foregroundStyle(UndrmndPrototypeTheme.accent)
    }

    /// Same typography as ``undrmndShellCtaTextStyle`` for use on dark / full-bleed backdrops.
    func undrmndShellCtaTextStyleOnDark() -> some View {
        self
            .font(.system(.body, design: .default))
            .fontWeight(.semibold)
            .foregroundStyle(.white)
    }

    /// Charcoal dashboards: Path sheet **Map** and Explore **Your Map** (isolate from Explore `.light`).
    func instrumentMapColorSchemeIsolation() -> some View {
        self
            .preferredColorScheme(.dark)
            .environment(\.colorScheme, .dark)
            .presentationBackground(InstrumentMapChrome.canvas)
    }
}
