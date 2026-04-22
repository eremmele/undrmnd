import Foundation

// MARK: - PathNode

enum PathNodeType: String, Codable, Hashable {
    case card
    case branch
    case endpoint
}

struct PathNode: Codable, Identifiable, Hashable {
    let id: UUID
    let nodeType: PathNodeType
    let content: ContentItem?
    let branchPrompt: String?
    let branchCompass: String?
    let endpointNote: String?
    let mapX: Int?
    let mapY: Int?
    let contributedBy: String?

    enum CodingKeys: String, CodingKey {
        case id, content
        case nodeType = "node_type"
        case branchPrompt = "branch_prompt"
        case branchCompass = "branch_compass"
        case endpointNote = "endpoint_note"
        case mapX = "map_x"
        case mapY = "map_y"
        case contributedBy = "contributed_by"
    }
}
