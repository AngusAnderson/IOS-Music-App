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
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                Button("Preview Queue") {
                    previewQueue()
                }
                .buttonStyle(.bordered)

                playbackSection

                childPlaylistsSection

                tracksSection
            }
            .padding()
        }
        .navigationTitle(node.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showPlaylistEditorSheet = true
                    } label: {
                        Label(
                            "New Playlist",
                            systemImage: "plus"
                        )
                    }

                    Button {
                        showingRenameSheet = true
                    } label: {
                        Label(
                            "Rename Playlist",
                            systemImage: "pencil"
                        )
                    }

                    Button {
                        showingAddSongsSheet = true
                    } label: {
                        Label(
                            "Add Songs",
                            systemImage: "music.note"
                        )
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

    // MARK: - Playback

    private var playbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playback")
                .font(.headline)

            Button {
                let traversal = selectedTraversal

                Task {
                    await playback.play(
                        node: node,
                        traversal: traversal
                    )
                }
            } label: {
                Label(
                    "Play This Playlist",
                    systemImage: "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(playback.isLoading)

            HStack {
                Button {
                    playback.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }

                Spacer()

                Button {
                    Task {
                        await playback.resume()
                    }
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
            }
            .buttonStyle(.bordered)
            .disabled(playback.isLoading)

            if playback.isLoading {
                ProgressView("Preparing Playback…")
            }

            if let errorMessage = playback.errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            if playback.skippedTrackCount > 0 {
                Text(
                    "\(playback.skippedTrackCount) track(s) "
                    + "could not be included."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Child playlists

    private var childPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Playlists")
                .font(.headline)

            if node.sortedChildren.isEmpty {
                Text("No child playlists yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(node.sortedChildren) { child in
                    NavigationLink {
                        PlaylistDetailView(node: child)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.tint)

                            Text(child.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(
                            Color.secondary.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .playlistDragAndDrop(for: child)
                    .playlistActions(for: child)
                }
            }
        }
    }

    // MARK: - Direct songs

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Songs")
                .font(.headline)

            if node.sortedTracks.isEmpty {
                Text("No songs added directly to this playlist.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(node.sortedTracks) { track in
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.body)

                            Text(track.artistName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .background(
                        Color.secondary.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
            }
        }
    }

    // MARK: - Debug queue preview

    private func previewQueue() {
        let tracks = PlaylistTreeService.collectTracks(
            from: node,
            traversal: selectedTraversal
        )

        for (index, track) in tracks.enumerated() {
            print("\(index + 1). \(track.title)")
        }
    }
}
