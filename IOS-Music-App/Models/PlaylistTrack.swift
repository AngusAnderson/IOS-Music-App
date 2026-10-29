import Foundation
import SwiftData

enum MusicReferenceSource: String, Codable {
    case sample
    case catalog
    case library
}

@Model
final class PlaylistTrack {
    @Attribute(.unique)
    var id: UUID
    
    var title: String
    var artistName: String
    var sortIndex: Int
    
    var musicItemID: String?
    
    var sourceRawValue: String
    
    var playlist: PlaylistNode?
    
    init(
        title: String,
        artistName: String,
        sortIndex: Int = 0,
        musicItemID: String? = nil,
        source: MusicReferenceSource = .sample
    ) {
        self.id = UUID()
        self.title = title
        self.artistName = artistName
        self.sortIndex = sortIndex
        self.musicItemID = musicItemID
        self.sourceRawValue = source.rawValue
    }
    
    var source: MusicReferenceSource {
        get {
            MusicReferenceSource(rawValue: sourceRawValue) ?? .sample
        }
        set {
            sourceRawValue = newValue.rawValue
        }
    }
}
