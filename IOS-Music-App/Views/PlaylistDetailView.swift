import SwiftUI

struct PlaylistDetailView: View {
    
    let node: PlaylistNode
    
    @State private var showPlaylistEditorSheet = false
    @State private var showingRenameSheet = false
    @State private var showingAddSongsSheet = false
    
    @EnvironmentObject private var playback: PlaybackService
    
    @AppStorage(PlaybackTraversal.storageKey)
    private var selectedTraversal: PlaybackTraversal = .depthFirst
    
    var body: some View {
        
        List {
            Button("Preview Queue") {
                let tracks = PlaylistTreeService.collectTracks(
                    from: node,
                    traversal: selectedTraversal
                )
                
                for (index, track) in tracks.enumerated() {
                    print("\(index + 1). \(track.title)")
                }
            }
            
            Section("Playback") {
                Button {
                    let traversal = selectedTraversal
                    
                    Task {
                        await playback.play(node: node, traversal: traversal)
                    }
                } label: {
                    Label("Play this playlist", systemImage: "play.fill")
                }
                .disabled(playback.isLoading)
                
                HStack {
                    Button("Pause") {
                        playback.pause()
                    }
                    
                    Spacer()
                    
                    Button("Resume") {
                        Task {
                            await playback.resume()
                        }
                    }
                }
                .buttonStyle(.borderless)
                .disabled(playback.isLoading)
                
                if playback.isLoading {
                    ProgressView("Preparing Playback...")
                }
                
                if let errorMessage = playback.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                
                if playback.skippedTrackCount > 0 {
                    Text("\(playback.skippedTrackCount) track(s) could not be included")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
            }
            
            
            if !node.children.isEmpty {
                Section("Playlists") {
                    ForEach(node.sortedChildren) { child in
                        NavigationLink {
                            PlaylistDetailView(node: child)
                        } label: {
                            Label(
                                child.name,
                                systemImage: "music.note.list"
                            )
                        }
                        .playlistActions(for: child)
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
