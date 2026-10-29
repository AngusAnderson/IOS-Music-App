import Foundation
import SwiftData

@MainActor
enum SampleLibrary {
    static func seedIfEmpty(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<PlaylistNode>()
        let existingCount = try context.fetchCount(descriptor)

        guard existingCount == 0 else {
            return
        }

        let heavy = PlaylistNode(
            name: "Heavy",
            sortIndex: 0
        )

        let favourites = PlaylistNode(
            name: "Favourites",
            sortIndex: 1
        )

        let metallica = PlaylistNode(
            name: "Metallica",
            sortIndex: 0
        )

        let megadeth = PlaylistNode(
            name: "Megadeth",
            sortIndex: 1
        )

        let earlyMetallica = PlaylistNode(
            name: "Early Albums",
            sortIndex: 0
        )

        let nodes = [
            heavy,
            favourites,
            metallica,
            megadeth,
            earlyMetallica
        ]

        for node in nodes {
            context.insert(node)
        }

        metallica.parent = heavy
        megadeth.parent = heavy
        earlyMetallica.parent = metallica

        // MARK: - Sample tracks

        addTracks(
            [
                ("Metallica Sample A", "Metallica"),
                ("Metallica Sample B", "Metallica")
            ],
            to: metallica,
            in: context
        )

        addTracks(
            [
                ("Early Metallica Sample A", "Metallica"),
                ("Early Metallica Sample B", "Metallica")
            ],
            to: earlyMetallica,
            in: context
        )

        addTracks(
            [
                ("Megadeth Sample A", "Megadeth"),
                ("Megadeth Sample B", "Megadeth")
            ],
            to: megadeth,
            in: context
        )

        addTracks(
            [
                ("Favourite Sample A", "Example Artist"),
                ("Favourite Sample B", "Another Artist")
            ],
            to: favourites,
            in: context
        )

        try context.save()
    }

    private static func addTracks(
        _ songs: [(title: String, artist: String)],
        to playlist: PlaylistNode,
        in context: ModelContext
    ) {
        for (index, song) in songs.enumerated() {
            let track = PlaylistTrack(
                title: song.title,
                artistName: song.artist,
                sortIndex: index
            )

            context.insert(track)
            track.playlist = playlist
        }
    }
}
