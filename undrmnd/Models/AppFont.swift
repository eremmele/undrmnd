import SwiftUI

// MARK: - Mass Driver: MD Lórien Trial (see MD-Trial EULA; bundle PostScript names use ASCII “Lorien”)

/// PostScript names (via CoreText) e.g. `MDLorien-BookTrial`, `MDLorien-SemiboldTrial`.
enum AppFont {
    private enum PostScript {
        static let book = "MDLorien-BookTrial"
        static let bookItalic = "MDLorien-BookItalicTrial"
        static let regular = "MDLorien-RegularTrial"
        static let italic = "MDLorien-ItalicTrial"
        static let semibold = "MDLorien-SemiboldTrial"
        static let semiboldItalic = "MDLorien-SemiboldItalicTrial"
        static let bold = "MDLorien-BoldTrial"
        static let boldItalic = "MDLorien-BoldItalicTrial"
        static let black = "MDLorien-BlackTrial"
        static let blackItalic = "MDLorien-BlackItalicTrial"
    }

    static var largeTitle: Font { .custom(PostScript.bold, size: 34, relativeTo: .largeTitle) }
    static var title: Font { .custom(PostScript.semibold, size: 28, relativeTo: .title) }
    static var title2: Font { .custom(PostScript.semibold, size: 22, relativeTo: .title2) }
    static var title3: Font { .custom(PostScript.semibold, size: 20, relativeTo: .title3) }
    static var headline: Font { .custom(PostScript.semibold, size: 17, relativeTo: .headline) }

    static var body: Font { .custom(PostScript.book, size: 17, relativeTo: .body) }
    static var bodyEmphasis: Font { .custom(PostScript.semibold, size: 17, relativeTo: .body) }
    static var bodyMedium: Font { .custom(PostScript.semibold, size: 17, relativeTo: .body) }
    static var bodySemibold: Font { .custom(PostScript.semibold, size: 17, relativeTo: .body) }
    static var callout: Font { .custom(PostScript.book, size: 16, relativeTo: .callout) }
    static var subheadline: Font { .custom(PostScript.book, size: 15, relativeTo: .subheadline) }
    static var subheadlineEmphasis: Font { .custom(PostScript.semibold, size: 15, relativeTo: .subheadline) }
    static var subheadlineStrong: Font { .custom(PostScript.semibold, size: 15, relativeTo: .subheadline) }

    static var footnote: Font { .custom(PostScript.book, size: 13, relativeTo: .footnote) }
    static var caption: Font { .custom(PostScript.book, size: 12, relativeTo: .caption) }
    static var captionEmphasis: Font { .custom(PostScript.semibold, size: 12, relativeTo: .caption) }
    static var caption2: Font { .custom(PostScript.book, size: 11, relativeTo: .caption2) }
    static var caption2Emphasis: Font { .custom(PostScript.semibold, size: 11, relativeTo: .caption2) }
    static var caption2Medium: Font { .custom(PostScript.semibold, size: 11, relativeTo: .caption2) }

    /// Open-question card title (replaces system serif 22)
    static var cardOrBranchTitle: Font { .custom(PostScript.semibold, size: 22, relativeTo: .title2) }
    static var branchPrompt: Font { .custom(PostScript.semibold, size: 20, relativeTo: .title3) }
    static var largeIntroTitle: Font { .custom(PostScript.semibold, size: 34, relativeTo: .largeTitle) }

    /// Nav bar wordmark — same size/weight as `navigationTitle` on other tabs (headline metrics + MD Lórien).
    static var brandWordmark: Font { headline }

    /// Map / closing-sheet micro labels: scales with Dynamic Type
    static func mapLabel(approxSize: CGFloat, mapWeight: MapWeight) -> Font {
        let name: String
        switch mapWeight {
        case .regular: name = PostScript.book
        case .medium, .semibold: name = PostScript.semibold
        }
        return .custom(name, size: approxSize, relativeTo: .caption2)
    }

    enum MapWeight {
        case regular, medium, semibold
    }
}
