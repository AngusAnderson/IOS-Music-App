import SwiftUI
import SwiftData
import MusicKit

struct ImportPlaylistsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var localNodes: [PlaylistNode]

    @State private var playlists: [Playlist] = []
    @State private var isLoading = true
    @State private var importingID: MusicItemID?

    @State private var errorMessage: String?
    @State private var importMessage: String?

    private let service = PlaylistImportService()

    private var importedIDs: Set<String> {
        Set(localNodes.compactMap(\.appleMusicPlaylistID))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(
                        "Import a local snapshot of an Apple Music playlist. "
                        + "Your original playlist will not be changed."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if isLoading {
                    Section {
                        ProgressView("Loading playlists…")
                    }
                } else if playlists.isEmpty {
                    Section {
                        Text("No library playlists found.")
                            .foregroundStyle(.secondary)

                        Button("Reload") {
                            Task {
                                await loadPlaylists()
                            }
                        }
                    }
                } else {
                    Section("Apple Music Playlists") {
                        ForEach(playlists) { playlist in
                            playlistRow(playlist)
                        }
                    }
                }

                if let importMessage {
                    Section("Last Import") {
                        Text(importMessage)
                    }
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Import Playlists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(importingID != nil)
                }
            }
            .interactiveDismissDisabled(importingID != nil)
            .task {
                await loadPlaylists()
            }
        }
    }

    private func playlistRow(_ playlist: Playlist) -> some View {
        let alreadyImported = importedIDs.contains(
            playlist.id.rawValue
        )

        return HStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .foregroundStyle(.tint)

            Text(playlist.name)

            Spacer()

            if importingID == playlist.id {
                ProgressView()
            } else if alreadyImported {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel("Already imported")
            } else {
                Button("Import") {
                    Task {
                        await importPlaylist(playlist)
                    }
                }
                .buttonStyle(.borderless)
                .disabled(importingID != nil)
            }
        }
    }

    @MainActor
    private func loadPlaylists() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            playlists = try await service.fetchPlaylists()
                .sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name)
                        == .orderedAscending
                }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func importPlaylist(_ playlist: Playlist) async {
        guard importingID == nil else {
            return
        }

        importingID = playlist.id
        errorMessage = nil
        importMessage = nil

        defer {
            importingID = nil
        }

        do {
            let result = try await service.importPlaylist(
                playlist,
                into: modelContext
            )

            importMessage = """
            Imported "\(result.name)" with \(result.importedSongs) songs.
            """

            if result.skippedItems > 0 {
                importMessage = (importMessage ?? "") + """
                
                Skipped \(result.skippedItems) non-song item(s).
                """
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
