import Foundation
import Combine
import MusicKit

@MainActor
final class PlaybackService: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var skippedTrackCount = 0
    @Published private(set) var activePlaylistName: String?
    
    @Published var errorMessage: String?
    
    let player = ApplicationMusicPlayer.shared
    
    func play(
        node: PlaylistNode,
        traversal: PlaybackTraversal = .depthFirst
    ) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        skippedTrackCount = 0
        
        defer { isLoading = false }
        
        do {
            try await checkPlaybackAccess()
            
            let tracks = PlaylistTreeService.collectTracks(
                from: node,
                traversal: traversal
            )
            
            guard !tracks.isEmpty else { throw PlaybackError.emptyPlaylist }
            
            let catalogIDs: [MusicItemID] = tracks.compactMap { track in
                guard
                    track.source == .catalog,
                    let rawID = track.musicItemID,
                    !rawID.isEmpty
                else {
                    return nil
                }
                
                return MusicItemID(rawID)
            }
            
            guard !catalogIDs.isEmpty else { throw PlaybackError.noCatalogTracks }
            
            let songsByID = try await fetchSongsByID(catalogIDs)
            
            let orderedSongs = catalogIDs.compactMap { songsByID[$0] }
            
            skippedTrackCount = tracks.count - orderedSongs.count
            
            guard !orderedSongs.isEmpty else { throw PlaybackError.noResolvedSongs }
            
            player.queue = ApplicationMusicPlayer.Queue(for: orderedSongs)
            
            player.state.shuffleMode = .off
            player.state.repeatMode = .none
            
            try await player.play()
            
            activePlaylistName = node.name
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func pause() {
        player.pause()
    }
    
    func resume() async {
        guard !isLoading else { return }
        
        errorMessage = nil
        
        guard !player.queue.entries.isEmpty else {
            errorMessage = "Choose a playlist to play first."
            return
        }
        
        do {
            try await player.play()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func togglePlayback() async {
        if player.state.playbackStatus == .playing {
            pause()
        } else {
            await resume()
        }
    }
    
    private func checkPlaybackAccess() async throws {
        let status: MusicAuthorization.Status
        
        if MusicAuthorization.currentStatus == .notDetermined {
            status = await MusicAuthorization.request()
        } else {
            status = MusicAuthorization.currentStatus
        }
        
        guard status == .authorized else {
            throw PlaybackError.permissionRequired
        }
        
        let subscription = try await MusicSubscription.current
        
        guard subscription.canPlayCatalogContent else {
            throw PlaybackError.subscriptionRequired
        }
    }
    
    private func fetchSongsByID(_ ids: [MusicItemID]) async throws -> [MusicItemID: Song] {
        var seen = Set<MusicItemID>()
        
        let uniqueIDs = ids.filter { id in
            seen.insert(id).inserted
        }
        
        var songsByID: [MusicItemID: Song] = [:]
        
        let batchSize = 25
        
        for start in stride(
            from: 0,
            to: uniqueIDs.count,
            by: batchSize
        ) {
            let end = min(start + batchSize, uniqueIDs.count)
            let batch = Array(uniqueIDs[start..<end])
            
            let request = MusicCatalogResourceRequest<Song>(
                matching: \.id,
                memberOf: batch
            )
            
            let response = try await request.response()
            
            for song in response.items {
                songsByID[song.id] = song
            }
        }
        
        return songsByID
    }
    
    func skipToNext() async {
        guard !isLoading else {
            return
        }

        errorMessage = nil

        do {
            try await player.skipToNextEntry()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func skipToPrevious() async {
        guard !isLoading else {
            return
        }

        errorMessage = nil

        do {
            try await player.skipToPreviousEntry()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum PlaybackError: LocalizedError {
    case permissionRequired
    case subscriptionRequired
    case emptyPlaylist
    case noCatalogTracks
    case noResolvedSongs
    
    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            return "Allow this app to access Apple Music in Settings before starting playback."
            
        case .subscriptionRequired:
            return "An Apple Music subscription with catalogue playback access is required to play these songs."
        
        case .emptyPlaylist:
            return "This playlist and its children contain no songs."
            
        case .noCatalogTracks:
            return "This playlist contains no supported Apple Music songs."
            
        case .noResolvedSongs:
            return "None of the saved songs could be found in the Apple Music catalogue."
        }
    }
}
