import Foundation
import SwiftData
import MusicKit

@MainActor
struct PlaylistImportService {
    struct ImportResult {
        let name: String
        let importedSongs: Int
        let skippedItems: Int
    }
    
    func fetchPlaylists() async throws -> [Playlist] {
        let status = await MusicAuthorization.request()
        
        guard status == .authorized else {
            throw ImportError.permissionRequired
        }
        
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()
        
        return try await allItems(in: response.items)
    }
    
    func importPlaylist(
        _ source: Playlist,
        into context: ModelContext
    ) async throws -> ImportResult {
        let existingNodes = try context.fetch(FetchDescriptor<PlaylistNode>())
        
        guard !existingNodes.contains(where: {
            $0.appleMusicPlaylistID == source.id.rawValue
        }) else {
            throw ImportError.alreadyImported
        }
        
        let detailedPlaylist = try await source.with(
            [.tracks],
            preferredSource: .library
        )
        
        guard let firstBatch = detailedPlaylist.tracks else {
            throw ImportError.tracksUnavaliable
        }
        
        let items = try await allItems(in: firstBatch)
        
        let nextIndex = (
            existingNodes
                .filter { $0.parent == nil }
                .map(\.sortIndex)
                .max() ?? -1
        ) + 1
        
        let node = PlaylistNode(
            name: source.name,
            sortIndex: nextIndex
        )
        
        node.appleMusicPlaylistID = source.id.rawValue
        
        context.insert(node)
        
        var insertedTracks: [PlaylistTrack] = []
        var skippedItems = 0
        
        for item in items {
            guard case let .song(song) = item else {
                skippedItems += 1
                continue
            }
            
            let track = PlaylistTrack(
                title: song.title,
                artistName: song.artistName,
                sortIndex: insertedTracks.count,
                musicItemID: song.id.rawValue,
                source: .library
            )
            
            context.insert(track)
            track.playlist = node
            
            insertedTracks.append(track)
        }
        
        do {
            try context.save()
        } catch {
            for track in insertedTracks {
                track.playlist = nil
                context.delete(track)
            }
            
            context.delete(node)
            throw error
        }
        
        return ImportResult(
            name: source.name,
            importedSongs: insertedTracks.count,
            skippedItems: skippedItems
        )
    }
    
    private func allItems<Item: MusicItem>(
        in firstBatch: MusicItemCollection<Item>
    ) async throws -> [Item] {
        var result = Array(firstBatch)
        var batch = firstBatch
        
        while batch.hasNextBatch {
            guard let next = try await batch.nextBatch() else { break }
            
            result.append(contentsOf: next)
            batch = next
        }
        
        return result
    }
}

private enum ImportError: LocalizedError {
    case permissionRequired
    case alreadyImported
    case tracksUnavaliable
    
    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            return "Allow Apple Music access before importing playlists."
            
        case .alreadyImported:
            return "This playlist has already been imported."
            
        case .tracksUnavaliable:
            return "The playlist's tracks could not be loaded"
        }
    }
}
