import SwiftUI
import SwiftData

@main struct MusicApp: App {
    
    @StateObject private var playback = PlaybackService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playback)
        }
        .modelContainer(
            for: [
                PlaylistNode.self,
                PlaylistTrack.self
            ]
        )
    }
}
