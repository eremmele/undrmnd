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

// MARK: - Navigation chrome (inline titles match the Explore “undrmnd” bar: MD Lórien headline)

extension View {
    /// Same typographic title treatment as the Explore tab’s custom principal label (`AppFont.brandWordmark`).
    func navigationTitleBrand(_ title: String) -> some View {
        navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(AppFont.brandWordmark)
                        .foregroundStyle(UndrmndPrototypeTheme.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
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
}
