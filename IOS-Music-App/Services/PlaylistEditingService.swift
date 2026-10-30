import Foundation
import SwiftData

@MainActor
enum PlaylistEditingService {
    static func canMove(
        _ node: PlaylistNode,
        to destination: PlaylistNode?
    ) -> Bool {
        if node.parent?.id == destination?.id {
            return false
        }
        
        var ancestor = destination
        var visited = Set<UUID>()

        while let current = ancestor {
            guard visited.insert(current.id).inserted else {
                return false
            }

            if current.id == node.id {
                return false
            }

            ancestor = current.parent
        }

        return true
    }

    static func move(
        _ node: PlaylistNode,
        to destination: PlaylistNode?,
        in context: ModelContext
    ) throws {
        guard canMove(node, to: destination) else {
            throw EditingError.invalidDestination
        }

        let allNodes = try context.fetch(
            FetchDescriptor<PlaylistNode>()
        )

        let siblings = allNodes.filter {
            $0.parent?.id == destination?.id && $0.id != node.id
        }

        let originalParent = node.parent
        let originalIndex = node.sortIndex

        node.parent = destination
        node.sortIndex =
            (siblings.map(\.sortIndex).max() ?? -1) + 1

        do {
            try context.save()
        } catch {
            node.parent = originalParent
            node.sortIndex = originalIndex
            throw error
        }
    }

    static func deleteKeepingChildren(
        _ node: PlaylistNode,
        in context: ModelContext
    ) throws {
        try context.save()

        do {
            let allNodes = try context.fetch(
                FetchDescriptor<PlaylistNode>()
            )

            var nextRootIndex = (
                allNodes
                    .filter { $0.parent == nil }
                    .map(\.sortIndex)
                    .max() ?? -1
            ) + 1

            let children = node.sortedChildren

            for child in children {
                child.parent = nil
                child.sortIndex = nextRootIndex
                nextRootIndex += 1
            }

            context.delete(node)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

private enum EditingError: LocalizedError {
    case invalidDestination

    var errorDescription: String? {
        "A playlist cannot be moved to its current location, itself, or one of its descendants."
    }
}
