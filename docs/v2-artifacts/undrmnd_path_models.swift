// undrmnd_path_models.swift
//
// v2 models — replace the v1 WalkPath structures. Paths are now read from
// Supabase via the `get_path(slug)` RPC, which returns a JSON blob of
// { path, nodes, edges }. The client renders the graph and the user navigates
// it any way they like — linearly or via the map view.
//
// Drop-in replacement guidance:
//   - Keep v1 WalkPathModels.swift temporarily if other files reference it.
//   - New code should import this file and use `Path`, `PathNode`, `PathEdge`.
//   - The Canvas-chat map view uses PathMap.nodes + PathMap.edges directly.

import Foundation

// MARK: - Pillars

enum Pillar: String, Codable, CaseIterable, Identifiable {
    case cosmos          = "cosmos"
    case livingWorld     = "living_world"
    case mindAndBrain    = "mind_and_brain"
    case howWeKnow       = "how_we_know"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cosmos:       return "Cosmos"
        case .livingWorld:  return "Living World"
        case .mindAndBrain: return "Mind & Brain"
        case .howWeKnow:    return "How We Know"
        }
    }
}

// MARK: - Interaction types (ways in)

enum InteractionType: String, Codable, CaseIterable {
    case read
    case reflect
    case observe
    case contribute

    var verb: String {
        switch self {
        case .read:       return "Read"
        case .reflect:    return "Reflect"
        case .observe:    return "Notice"
        case .contribute: return "Contribute"
        }
    }
}

// MARK: - ContentItem (one card)

struct ContentItem: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let hook: String
    let body: String?
    let interactionType: InteractionType
    let tags: [String]
    let sourceCitation: String?
    let sourceURL: URL?
    let actionURL: URL?
    let topic: Pillar
    let estimatedTimeMinutes: Int
    let isOpenQuestion: Bool
    let isActive: Bool
    let contributedBy: String?   // username handle

    enum CodingKeys: String, CodingKey {
        case id, title, hook, body, tags, topic
        case interactionType       = "interaction_type"
        case sourceCitation        = "source_citation"
        case sourceURL             = "source_url"
        case actionURL             = "action_url"
        case estimatedTimeMinutes  = "estimated_time_minutes"
        case isOpenQuestion        = "is_open_question"
        case isActive              = "is_active"
        case contributedBy         = "contributed_by"
    }
}

// MARK: - Profile

struct Profile: Codable, Identifiable, Hashable {
    let id: UUID
    let username: String
    let displayName: String?
    let bio: String?
    let pillarsFollowing: [Pillar]
    let contributionsCount: Int   // cards authored; NOT a streak, NOT karma
    let isContributor: Bool
    let joinedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName          = "display_name"
        case pillarsFollowing     = "pillars_following"
        case contributionsCount   = "contributions_count"
        case isContributor        = "is_contributor"
        case joinedAt             = "joined_at"
    }
}

// MARK: - Path

struct Path: Codable, Identifiable, Hashable {
    let id: UUID
    let slug: String
    let title: String
    let subtitle: String?
    let topic: Pillar
    let isActive: Bool
    let isFeatured: Bool

    enum CodingKeys: String, CodingKey {
        case id, slug, title, subtitle, topic
        case isActive   = "is_active"
        case isFeatured = "is_featured"
    }
}

// MARK: - PathNode

enum PathNodeType: String, Codable {
    case card
    case branch
    case endpoint
}

struct PathNode: Codable, Identifiable, Hashable {
    let id: UUID
    let nodeType: PathNodeType
    let content: ContentItem?      // non-nil when nodeType == .card
    let branchPrompt: String?      // non-nil when nodeType == .branch
    let branchCompass: String?
    let endpointNote: String?      // non-nil when nodeType == .endpoint
    let mapX: Int?
    let mapY: Int?
    let contributedBy: String?     // per-node byline; path has no single author

    enum CodingKeys: String, CodingKey {
        case id, content
        case nodeType      = "node_type"
        case branchPrompt  = "branch_prompt"
        case branchCompass = "branch_compass"
        case endpointNote  = "endpoint_note"
        case mapX          = "map_x"
        case mapY          = "map_y"
        case contributedBy = "contributed_by"
    }
}

// MARK: - PathEdge

struct PathEdge: Codable, Hashable {
    let fromNodeId: UUID
    let toNodeId: UUID
    let choiceLabel: String?     // required when `fromNodeId` is a branch
    let choicePreview: String?
    let orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case fromNodeId    = "from_node_id"
        case toNodeId      = "to_node_id"
        case choiceLabel   = "choice_label"
        case choicePreview = "choice_preview"
        case orderIndex    = "order_index"
    }
}

// MARK: - PathMap — decoded response from the `get_path(slug)` RPC

struct PathMap: Codable {
    let path: Path
    let nodes: [PathNode]
    let edges: [PathEdge]

    /// Root nodes = nodes with no incoming edges. Typically exactly one.
    var rootNodes: [PathNode] {
        let incoming = Set(edges.map(\.toNodeId))
        return nodes.filter { !incoming.contains($0.id) }
    }

    /// Endpoint nodes = node_type == .endpoint (or any node with no outgoing edges).
    var terminalNodes: [PathNode] {
        let outgoing = Set(edges.map(\.fromNodeId))
        return nodes.filter {
            $0.nodeType == .endpoint || !outgoing.contains($0.id)
        }
    }

    /// Outgoing edges for a given node, ordered.
    func outgoing(from nodeId: UUID) -> [PathEdge] {
        edges
            .filter { $0.fromNodeId == nodeId }
            .sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Node lookup helper — O(1) after first call if you cache the result.
    func node(_ id: UUID) -> PathNode? {
        nodes.first { $0.id == id }
    }
}

// MARK: - PathMapLayout — for the Canvas-chat-style map view

/// Computes (x, y) screen positions for every node in the map.
/// Uses stored map_x / map_y when present; auto-layouts with a simple
/// breadth-first algorithm when they're nil.
struct PathMapLayout {
    struct Position: Hashable {
        let nodeId: UUID
        let x: Int
        let y: Int
    }

    let positions: [Position]

    init(map: PathMap) {
        // If every node has explicit coordinates, trust them.
        if map.nodes.allSatisfy({ $0.mapX != nil && $0.mapY != nil }) {
            self.positions = map.nodes.map {
                Position(nodeId: $0.id, x: $0.mapX!, y: $0.mapY!)
            }
            return
        }

        // Otherwise BFS from the root, assigning y = depth and spreading x.
        var positions: [Position] = []
        var visited = Set<UUID>()
        var frontier: [(UUID, Int)] = map.rootNodes.map { ($0.id, 0) }
        var depthBuckets: [Int: [UUID]] = [:]

        while let (nodeId, depth) = frontier.first {
            frontier.removeFirst()
            if visited.contains(nodeId) { continue }
            visited.insert(nodeId)
            depthBuckets[depth, default: []].append(nodeId)
            for edge in map.outgoing(from: nodeId) {
                frontier.append((edge.toNodeId, depth + 1))
            }
        }

        for (depth, ids) in depthBuckets {
            let count = ids.count
            for (i, id) in ids.enumerated() {
                // Center nodes around x = 0.
                let x = count == 1 ? 0 : (i - (count - 1) / 2)
                positions.append(Position(nodeId: id, x: x, y: depth))
            }
        }

        self.positions = positions
    }

    func position(for nodeId: UUID) -> Position? {
        positions.first { $0.nodeId == nodeId }
    }
}

// MARK: - Session (unchanged from v1)

struct Session: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let startedAt: Date
    let completedAt: Date?
    let status: String
    let cardsServedCount: Int
    let cardsCompletedCount: Int

    enum CodingKeys: String, CodingKey {
        case id, status
        case userId              = "user_id"
        case startedAt           = "started_at"
        case completedAt         = "completed_at"
        case cardsServedCount    = "cards_served_count"
        case cardsCompletedCount = "cards_completed_count"
    }
}
