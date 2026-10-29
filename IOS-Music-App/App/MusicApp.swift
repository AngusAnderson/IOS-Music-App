import SwiftUI
import SwiftData

@main struct MusicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: [
                PlaylistNode.self,
                PlaylistTrack.self
            ]
        )
    }
}
