import SwiftUI

struct PlaylistDetailView: View {
    
    let node: PlaylistNode
    
    var body: some View {
        List {
            Section("playlists") {
                ForEach(node.sortedChildren) { child in
                    NavigationLink {
                        PlaylistDetailView(node: child)
                    } label: {
                        Label(child.name, systemImage: "music.note.list")
                    }
                }
            }
            
            if !node.sortedTracks.isEmpty {
                Section("Songs") {
                    ForEach(node.sortedTracks) { track in
                        VStack(alignment: .leading) {
                            Text(track.title)
                            
                            Text(track.artistName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            
        }
        .navigationTitle(node.name)
    }
}
