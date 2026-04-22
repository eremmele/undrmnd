import Foundation

// MARK: - PathMap (decoded from `get_path(slug)` RPC)

struct PathMap: Codable {
    let path: PathRecord?
    let nodes: [PathNode]
    let edges: [PathEdge]

    /// Root nodes = nodes with no incoming edges. Typically exactly one.
    var rootNodes: [PathNode] {
        let incoming = Set(edges.map(\.toNodeId))
        return nodes.filter { !incoming.contains($0.id) }
    }

    /// Endpoint or leaf nodes.
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

    func node(_ id: UUID) -> PathNode? {
        nodes.first { $0.id == id }
    }
}
