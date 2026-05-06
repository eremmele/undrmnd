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
            let raw = map.nodes.map {
                Position(nodeId: $0.id, x: $0.mapX!, y: $0.mapY!)
            }
            let distinctCells = Set(raw.map { Self.cellKey(x: $0.x, y: $0.y) })
            // Degenerate payloads (every node stamped with the same cell) collapse the graph in UI.
            if distinctCells.count <= 1 && raw.count > 1 {
                self.positions = Self.computeBFSLayout(map: map)
            } else {
                self.positions = Self.spreadCollidingGridPositions(raw)
            }
            return
        }

        self.positions = Self.computeBFSLayout(map: map)
    }

    func position(for nodeId: UUID) -> Position? {
        positions.first { $0.nodeId == nodeId }
    }

    private static func cellKey(x: Int, y: Int) -> String { "\(x),\(y)" }

    /// Resolves overlapping server coordinates so node labels and edge chips don't stack.
    private static func spreadCollidingGridPositions(_ input: [Position]) -> [Position] {
        var occupied = Set<String>()
        var out: [Position] = []
        out.reserveCapacity(input.count)
        for p in input {
            var x = p.x
            let y = p.y
            var safety = 0
            while occupied.contains(cellKey(x: x, y: y)) && safety < 96 {
                x += 1
                safety += 1
            }
            occupied.insert(cellKey(x: x, y: y))
            out.append(Position(nodeId: p.nodeId, x: x, y: y))
        }
        return out
    }

    private static func computeBFSLayout(map: PathMap) -> [Position] {
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

        return positions
    }
}
