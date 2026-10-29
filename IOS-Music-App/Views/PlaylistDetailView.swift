import SwiftUI

struct PlaylistDetailView: View {
    
    let node: PlaylistNode
    
    @State private var showPlaylistEditorSheet = false
    @State private var showingRenameSheet = false
    @State private var showingAddSongsSheet = false
    
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showPlaylistEditorSheet = true
                    } label: {
                        Label("New Playlist", systemImage: "plus")
                    }
                    
                    Button {
                        showingRenameSheet = true
                    } label: {
                        Label("Rename Playlist", systemImage: "pencil")
                    }
                    
                    Button {
                        showingAddSongsSheet = true
                    } label: {
                        Label("Add Songs", systemImage: "music.note")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showPlaylistEditorSheet) {
            PlaylistEditorSheet(parent: node)
        }
        .sheet(isPresented: $showingRenameSheet) {
            PlaylistEditorSheet(playlistToEdit: node)
        }
        .sheet(isPresented: $showingAddSongsSheet) {
            AddSongsSheet(playlist: node)
        }
    }
}
