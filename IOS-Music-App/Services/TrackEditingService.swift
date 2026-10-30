import Foundation
import SwiftData

@MainActor
enum TrackEditingService {
    static func reorder(
        _ track: PlaylistTrack,
        direction: ReorderDirection,
        in context: ModelContext
    ) throws {
        guard let playlist = track.playlist else {
            return
        }

        var tracks = playlist.tracks.sorted { first, second in
            if first.sortIndex != second.sortIndex {
                return first.sortIndex < second.sortIndex
            }

            return first.id.uuidString < second.id.uuidString
        }

        guard let currentIndex = tracks.firstIndex(
            where: { $0.id == track.id }
        ) else {
            return
        }

        let destinationIndex = currentIndex + direction.offset

        guard tracks.indices.contains(destinationIndex) else {
            return
        }

        let originalIndexes = tracks.map {
            (track: $0, sortIndex: $0.sortIndex)
        }

        tracks.swapAt(currentIndex, destinationIndex)

        for (index, item) in tracks.enumerated() {
            if item.sortIndex != index {
                item.sortIndex = index
            }
        }

        do {
            try context.save()
        } catch {
            for original in originalIndexes {
                original.track.sortIndex = original.sortIndex
            }

            throw error
        }
    }
}
