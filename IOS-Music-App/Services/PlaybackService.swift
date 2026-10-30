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
        guard !isLoading else {
            return
        }

        isLoading = true
        errorMessage = nil
        skippedTrackCount = 0

        defer {
            isLoading = false
        }

        do {
            try await checkPlaybackAccess()

            let tracks = PlaylistTreeService.collectTracks(
                from: node,
                traversal: traversal
            )

            guard !tracks.isEmpty else {
                throw PlaybackError.emptyPlaylist
            }

            var catalogIDs: [MusicItemID] = []
            var libraryIDs: [MusicItemID] = []

            for track in tracks {
                guard
                    let rawID = track.musicItemID,
                    !rawID.isEmpty
                else {
                    continue
                }

                let id = MusicItemID(rawID)

                switch track.source {
                case .catalog:
                    catalogIDs.append(id)

                case .library:
                    libraryIDs.append(id)

                case .sample:
                    break
                }
            }

            guard !catalogIDs.isEmpty || !libraryIDs.isEmpty else {
                throw PlaybackError.noSupportedTracks
            }

            let catalogSongs = try await fetchSongsByID(catalogIDs)
            let librarySongs = try await resolveLibrarySongs(
                for: tracks,
                ids: libraryIDs
            )

            let orderedSongs: [Song] = tracks.compactMap { track in
                guard let rawID = track.musicItemID else {
                    return nil
                }

                let id = MusicItemID(rawID)

                switch track.source {
                case .catalog:
                    return catalogSongs[id]

                case .library:
                    return librarySongs[id]

                case .sample:
                    return nil
                }
            }

            skippedTrackCount = tracks.count - orderedSongs.count

            guard !orderedSongs.isEmpty else {
                throw PlaybackError.noResolvedSongs
            }

            player.queue = ApplicationMusicPlayer.Queue(
                for: orderedSongs
            )

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
    
    private func fetchLibrarySongsByID(
        _ ids: [MusicItemID]
    ) async throws -> [MusicItemID: Song] {
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

            var request = MusicLibraryRequest<Song>()

            request.filter(
                matching: \.id,
                memberOf: batch
            )

            let response = try await request.response()

            var page = response.items

            for song in page {
                songsByID[song.id] = song
            }

            while page.hasNextBatch {
                guard let next = try await page.nextBatch() else {
                    break
                }

                for song in next {
                    songsByID[song.id] = song
                }

                page = next
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
    
    private func resolveLibrarySongs(
        for tracks: [PlaylistTrack],
        ids: [MusicItemID]
    ) async throws -> [MusicItemID: Song] {
        guard !ids.isEmpty else {
            return [:]
        }

        var songsByID = try await fetchLibrarySongsByID(ids)

        let wantedIDs = Set(ids)

        guard !wantedIDs.isSubset(of: Set(songsByID.keys)) else {
            return songsByID
        }

        let sourcePlaylistIDs = Set(
            tracks.compactMap { track -> String? in
                guard track.source == .library else {
                    return nil
                }

                return track.playlist?.appleMusicPlaylistID
            }
        )

        for rawPlaylistID in sourcePlaylistIDs {
            var request = MusicLibraryRequest<Playlist>()

            request.filter(
                matching: \.id,
                equalTo: MusicItemID(rawPlaylistID)
            )

            let response = try await request.response()

            guard let sourcePlaylist = response.items.first else {
                print("Source playlist not found:", rawPlaylistID)
                continue
            }

            let detailedPlaylist = try await sourcePlaylist.with(
                [.tracks],
                preferredSource: .library
            )

            guard var page = detailedPlaylist.tracks else {
                print("Source playlist has no loaded tracks:", rawPlaylistID)
                continue
            }

            while true {
                for item in page {
                    guard case let .song(song) = item else {
                        continue
                    }

                    if wantedIDs.contains(song.id) {
                        songsByID[song.id] = song
                    }
                }

                guard
                    page.hasNextBatch,
                    let nextPage = try await page.nextBatch()
                else {
                    break
                }

                page = nextPage
            }
        }

        print(
            "Library resolution:",
            songsByID.count,
            "matched songs for",
            wantedIDs.count,
            "unique saved IDs"
        )

        return songsByID
    }
}

private enum PlaybackError: LocalizedError {
    case permissionRequired
    case subscriptionRequired
    case emptyPlaylist
    case noSupportedTracks
    case noResolvedSongs

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            return """
            Allow this app to access Apple Music in Settings \
            before starting playback.
            """

        case .subscriptionRequired:
            return """
            This version of the app requires Apple Music \
            catalogue playback access.
            """

        case .emptyPlaylist:
            return "This playlist and its children contain no songs."

        case .noSupportedTracks:
            return """
            This playlist contains no supported music references. \
            Sample tracks cannot be played.
            """

        case .noResolvedSongs:
            return """
            None of the saved songs could be resolved from \
            Apple Music or your music library.
            """
        }
    }
}
