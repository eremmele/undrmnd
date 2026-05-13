import XCTest
@testable import undrmnd

final class UndrmndTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here.
    }

    override func tearDownWithError() throws {
        // Put teardown code here.
    }

    func testExample() throws {
        XCTAssertTrue(true)
    }

    func testSemanticSearch_sentenceEmbeddingAvailability() {
        XCTAssertTrue(
            SemanticSearchRanker.isSentenceEmbeddingAvailable,
            "English sentence embeddings should load on iOS 17+ simulators and devices."
        )
    }

    func testSemanticSearch_selfSimilarityIsHigh() {
        let q = "dark matter in galaxies"
        let s = SemanticSearchRanker.embeddingSimilarity(query: q, document: q)
        XCTAssertGreaterThan(s, 0.92, "Self-match should map near 1.0 after cosine→[0,1].")
    }

    func testSemanticSearch_relatedTopicScoresAboveUnrelated() {
        let q = "life in the deep ocean"
        let relatedDoc = "marine animals and plankton in the abyssal zone"
        let unrelatedDoc = "quarterly earnings and stock buybacks"
        let r = SemanticSearchRanker.embeddingSimilarity(query: q, document: relatedDoc)
        let u = SemanticSearchRanker.embeddingSimilarity(query: q, document: unrelatedDoc)
        XCTAssertGreaterThan(r, u, "Embedding ranker should score related prose above unrelated prose.")
        XCTAssertGreaterThan(r, 0.35)
    }
}
