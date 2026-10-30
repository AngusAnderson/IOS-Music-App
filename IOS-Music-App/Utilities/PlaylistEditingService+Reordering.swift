import Foundation
import SwiftData

extension PlaylistEditingService {
    static func reorder(
        _ node: PlaylistNode,
        direction: ReorderDirection,
        in context: ModelContext
    ) throws {
        let allNodes = try context.fetch(
            FetchDescriptor<PlaylistNode>()
        )

        var siblings = allNodes
            .filter { candidate in
                candidate.parent?.id == node.parent?.id
            }
            .sorted { first, second in
                if first.sortIndex != second.sortIndex {
                    return first.sortIndex < second.sortIndex
                }

                return first.id.uuidString < second.id.uuidString
            }

        guard let currentIndex = siblings.firstIndex(
            where: { $0.id == node.id }
        ) else {
            return
        }

        let destinationIndex = currentIndex + direction.offset

        guard siblings.indices.contains(destinationIndex) else {
            return
        }

        let originalIndexes = siblings.map {
            (node: $0, sortIndex: $0.sortIndex)
        }

        siblings.swapAt(currentIndex, destinationIndex)

        for (index, sibling) in siblings.enumerated() {
            if sibling.sortIndex != index {
                sibling.sortIndex = index
            }
        }

        do {
            try context.save()
        } catch {
            for original in originalIndexes {
                original.node.sortIndex = original.sortIndex
            }

            throw error
        }
    }
}
