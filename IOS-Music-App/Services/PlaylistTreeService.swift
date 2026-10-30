enum PlaylistTreeService {
    static func collectTracks(
        from node: PlaylistNode,
        traversal: PlaybackTraversal = .depthFirst
    ) -> [PlaylistTrack] {
        switch traversal {
        case .depthFirst:
            return collectDepthFirst(from: node)

        case .breadthFirst:
            return collectBreadthFirst(from: node)
        }
    }

    // MARK: - DFS

    private static func collectDepthFirst(
        from node: PlaylistNode
    ) -> [PlaylistTrack] {
        var result = node.sortedTracks

        for child in node.sortedChildren {
            result.append(
                contentsOf: collectDepthFirst(from: child)
            )
        }

        return result
    }

    // MARK: - BFS

    private static func collectBreadthFirst(
        from node: PlaylistNode
    ) -> [PlaylistTrack] {
        var result: [PlaylistTrack] = []

        var pendingNodes: [PlaylistNode] = [node]
        var readIndex = 0

        while readIndex < pendingNodes.count {
            let current = pendingNodes[readIndex]
            readIndex += 1

            result.append(contentsOf: current.sortedTracks)
            pendingNodes.append(contentsOf: current.sortedChildren)
        }

        return result
    }
}
