import Foundation

/// Stand-in for an embedding-backed retriever: **token overlap only** (no generative text, no user-facing “AI”).
/// Real embeddings can plug in later with the same score contract (`0...1`).
enum SemanticSearchRanker {
    /// Normalized overlap: fraction of query tokens that appear in `document` (case- and diacritic-insensitive).
    static func normalizedTokenOverlap(query: String, document: String) -> Double {
        let qTokens = tokenize(query)
        guard !qTokens.isEmpty else { return 0 }
        let dTokens = Set(tokenize(document))
        let hits = qTokens.filter { dTokens.contains($0) }.count
        return Double(hits) / Double(qTokens.count)
    }

    private static func tokenize(_ s: String) -> [String] {
        let folded = s.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        return folded.split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 1 }
    }
}
