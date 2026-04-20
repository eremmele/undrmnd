import SwiftUI

/// Visual tokens from the web prototype (`index.html` / bundled theme object).
enum UndrmndPrototypeTheme {
    static let paper = Color(red: 0.98, green: 0.976, blue: 0.969)
    static let panel = Color(red: 0.957, green: 0.953, blue: 0.945)
    static let divider = Color(red: 0.914, green: 0.910, blue: 0.902)
    static let muted = Color(red: 0.769, green: 0.765, blue: 0.757)
    static let secondary = Color(red: 0.541, green: 0.537, blue: 0.529)
    static let primary = Color(red: 0.173, green: 0.173, blue: 0.169)
    /// Vite `INK.accent` — deep ink for filled controls.
    static let accent = Color(red: 0.102, green: 0.102, blue: 0.098)
}
