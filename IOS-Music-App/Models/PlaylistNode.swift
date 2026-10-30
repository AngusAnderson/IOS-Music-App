import Foundation
import SwiftData

@Model
final class PlaylistNode {
    @Attribute(.unique)
    var id: UUID
    var name: String
    var sortIndex: Int
    var createdAt: Date
    var appleMusicPlaylistID: String? = nil
    
    var parent: PlaylistNode?
    
    @Relationship(
        deleteRule: .nullify,
        inverse: \PlaylistNode.parent
    )
    var children: [PlaylistNode] = []
    
    @Relationship(
        deleteRule: .cascade,
        inverse: \PlaylistTrack.playlist
    )
    var tracks: [PlaylistTrack] = []
    
    init(
        name: String,
        sortIndex: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.sortIndex = sortIndex
        self.createdAt = .now
    }
    
    var sortedChildren: [PlaylistNode] {
        children.sorted { $0.sortIndex < $1.sortIndex}
    }
    
    var sortedTracks: [PlaylistTrack] {
        tracks.sorted { $0.sortIndex < $1.sortIndex }
    }
    
    var isRoot: Bool {
        parent == nil
    }
    
    
}
