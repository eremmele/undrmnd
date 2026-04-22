import Foundation

// MARK: - PathEdge

struct PathEdge: Codable, Hashable {
    let fromNodeId: UUID
    let toNodeId: UUID
    let choiceLabel: String?
    let choicePreview: String?
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case fromNodeId = "from_node_id"
        case toNodeId = "to_node_id"
        case choiceLabel = "choice_label"
        case choicePreview = "choice_preview"
        case orderIndex = "order_index"
    }
}
