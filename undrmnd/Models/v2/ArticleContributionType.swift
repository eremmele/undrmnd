import Foundation

/// Branch contribution type from the articles schema.
enum ArticleContributionType: String, Codable, Hashable, Sendable, CaseIterable {
    case observation
    case experiment
    case reinterpretation
    case translation
    case synthesis
    case dataset
}
