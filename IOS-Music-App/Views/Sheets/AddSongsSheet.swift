import SwiftUI
import SwiftData
import MusicKit

struct AddSongsSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let playlist: PlaylistNode

    @State private var searchText = ""
    @State private var results: [Song] = []

    @State private var isSearching = false
    @State private var hasSearched = false

    @State private var searchError: String?
    @State private var saveError: String?

    private let musicService = AppleMusicService()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField(
                        "Search songs or artists",
                        text: $searchText
                    )
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .onSubmit {
                        guard !isSearching else {
                            return
                        }

                        Task {
                            await search()
                        }
                    }

                    Button("Search") {
                        Task {
                            await search()
                        }
                    }
                    .disabled(
                        isSearching ||
                        searchText.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }

                if isSearching {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Searching Apple Music…")
                            Spacer()
                        }
                    }
                } else if let searchError {
                    Section {
                        Text(searchError)
                            .foregroundStyle(.red)
                    }
                } else if !hasSearched {
                    Section {
                        Text("Search for songs to add to this playlist.")
                            .foregroundStyle(.secondary)
                    }
                } else if results.isEmpty {
                    Section {
                        Text("No songs found. Try another search.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Results") {
                        ForEach(results) { song in
                            songRow(song)
                        }
                    }
                }
            }
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(
                "Could Not Add Song",
                isPresented: Binding(
                    get: { saveError != nil },
                    set: { isPresented in
                        if !isPresented {
                            saveError = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    saveError = nil
                }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private func songRow(_ song: Song) -> some View {
        let isAdded = contains(song)

        return HStack(spacing: 12) {
            if let artwork = song.artwork {
                ArtworkImage(
                    artwork,
                    width: 48,
                    height: 48
                )
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "music.note")
                    .frame(width: 48, height: 48)
                    .background(.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.body)

                Text(song.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                addSong(song)
            } label: {
                Image(
                    systemName: isAdded
                        ? "checkmark.circle.fill"
                        : "plus.circle"
                )
                .font(.title2)
                .foregroundStyle(isAdded ? Color.green : Color.accentColor)
            }
            .buttonStyle(.borderless)
            .disabled(isAdded)
            .accessibilityLabel(
                isAdded
                    ? "\(song.title) already added"
                    : "Add \(song.title)"
            )
        }
    }

    @MainActor
    private func search() async {
        let term = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !term.isEmpty, !isSearching else {
            return
        }

        isSearching = true
        hasSearched = true
        searchError = nil
        results = []

        defer {
            isSearching = false
        }

        do {
            results = try await musicService.searchSongs(term: term)
        } catch {
            let nsError = error as NSError

                print("MusicKit error:", error)
                print("Domain:", nsError.domain)
                print("Code:", nsError.code)
                print("Details:", nsError.userInfo)

            searchError = """
            Could not search Apple Music. \(error.localizedDescription)
            """
        }
    }

    private func contains(_ song: Song) -> Bool {
        playlist.tracks.contains { track in
            track.source == .catalog &&
            track.musicItemID == song.id.rawValue
        }
    }

    @MainActor
    private func addSong(_ song: Song) {
        guard !contains(song) else {
            return
        }

        let nextIndex =
            (playlist.tracks.map(\.sortIndex).max() ?? -1) + 1

        let track = PlaylistTrack(
            title: song.title,
            artistName: song.artistName,
            sortIndex: nextIndex,
            musicItemID: song.id.rawValue,
            source: .catalog
        )

        modelContext.insert(track)
        track.playlist = playlist

        do {
            try modelContext.save()
        } catch {
            track.playlist = nil
            modelContext.delete(track)

            saveError = error.localizedDescription
        }
    }
}
