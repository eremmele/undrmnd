import Foundation
import NaturalLanguage

/// On-device **sentence / word embeddings** (Apple `NaturalLanguage`) for retrieval-style ranking.
/// No generative text and no server-side model calls — cosine similarity only, mapped to `0...1`.
enum SemanticSearchRanker {
    /// `1` = identical embedding direction; `0` = orthogonal or unknown.
    static func embeddingSimilarity(query: String, document: String) -> Double {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = document.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !d.isEmpty else { return 0 }
        guard let qv = vector(for: q), let dv = vector(for: d), qv.count == dv.count else { return 0 }
        let c = cosineSimilarity(qv, dv)
        return (c + 1) / 2
    }

    /// True when Apple sentence embeddings are available (used by tests / diagnostics).
    static var isSentenceEmbeddingAvailable: Bool {
        NLEmbedding.sentenceEmbedding(for: .english) != nil
    }

    // MARK: - Internals

    private static func vector(for text: String) -> [Double]? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        if let emb = NLEmbedding.sentenceEmbedding(for: .english), let v = emb.vector(for: t), !v.isEmpty {
            return v
        }
        return averagedWordEmbedding(for: t)
    }

    private static func averagedWordEmbedding(for text: String) -> [Double]? {
        guard let wemb = NLEmbedding.wordEmbedding(for: .english) else { return nil }
        let tokens = text.split { !$0.isLetter && !$0.isNumber }.map { String($0).lowercased() }.filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }
        var accumulator: [Double]?
        var count = 0
        for tok in tokens.prefix(64) {
            guard let v = wemb.vector(for: tok), !v.isEmpty else { continue }
            if var acc = accumulator {
                for i in 0 ..< min(acc.count, v.count) {
                    acc[i] += v[i]
                }
                accumulator = acc
            } else {
                accumulator = v
            }
            count += 1
        }
        guard var s = accumulator, count > 0 else { return nil }
        let inv = 1.0 / Double(count)
        for i in 0 ..< s.count {
            s[i] *= inv
        }
        return s
    }

    private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let n = min(a.count, b.count)
        guard n > 0 else { return 0 }
        var dot = 0.0
        var na = 0.0
        var nb = 0.0
        for i in 0 ..< n {
            dot += a[i] * b[i]
            na += a[i] * a[i]
            nb += b[i] * b[i]
        }
        let denom = (na.squareRoot() * nb.squareRoot())
        guard denom > 1e-9 else { return 0 }
        return max(-1, min(1, dot / denom))
    }
}
