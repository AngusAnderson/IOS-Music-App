import Foundation
import SwiftData

enum PlaylistTreeService {
    static func collectTracks(from node: PlaylistNode) -> [PlaylistTrack] {
        var result = node.sortedTracks
        
        for child in node.sortedChildren {
            result.append(contentsOf: collectTracks(from: child))
        }
        
        return result
    }
}
