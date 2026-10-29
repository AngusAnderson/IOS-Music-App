import SwiftUI

struct PlaylistDetailView: View {
    
    let node: PlaylistNode
    
    var body: some View {
        List {
            
            Button("Preview Queue") {
                let tracks = PlaylistTreeService.collectTracks(from: node)
                
                for (index, track) in tracks.enumerated() {
                    print("\(index + 1). \(track.title)")
                }
            }
            
            if !node.children.isEmpty {
                Section("playlists") {
                    ForEach(node.sortedChildren) { child in
                        NavigationLink {
                            PlaylistDetailView(node: child)
                        } label: {
                            Label(child.name, systemImage: "music.note.list")
                        }
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
