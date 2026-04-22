import Foundation

// MARK: - PathMapLayout (Canvas-style map layout)

struct PathMapLayout {
    struct Position: Hashable {
        let nodeId: UUID
        let x: Int
        let y: Int
    }

    let positions: [Position]

    init(map: PathMap) {
        if map.nodes.allSatisfy({ $0.mapX != nil && $0.mapY != nil }) {
            self.positions = map.nodes.map {
                Position(nodeId: $0.id, x: $0.mapX!, y: $0.mapY!)
            }
            return
        }

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

        for depth in depthBuckets.keys.sorted() {
            guard let ids = depthBuckets[depth] else { continue }
            let count = ids.count
            for (i, id) in ids.enumerated() {
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
