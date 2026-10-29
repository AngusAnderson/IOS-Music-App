import SwiftUI
import SwiftData

struct PlaylistEditorSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allNodes: [PlaylistNode]

    private let parent: PlaylistNode?
    private let playlistToEdit: PlaylistNode?

    @State private var name: String
    @State private var errorMessage: String?

    init(parent: PlaylistNode?) {
        self.parent = parent
        self.playlistToEdit = nil
        self._name = State(initialValue: "")
    }

    init(playlistToEdit: PlaylistNode) {
        self.parent = playlistToEdit.parent
        self.playlistToEdit = playlistToEdit
        self._name = State(initialValue: playlistToEdit.name)
    }

    private var isRenaming: Bool {
        playlistToEdit != nil
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nextSortIndex: Int {
        let siblings: [PlaylistNode]

        if let parent {
            siblings = parent.children
        } else {
            siblings = allNodes.filter { $0.parent == nil }
        }

        return (siblings.map(\.sortIndex).max() ?? -1) + 1
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Playlist Name") {
                    TextField("Playlist name", text: $name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit {
                            save()
                        }
                }

                Section("Location") {
                    Label(
                        parent?.name ?? "Your Library",
                        systemImage: "music.note.list"
                    )
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(
                isRenaming ? "Rename Playlist" : "New Playlist"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isRenaming ? "Save" : "Create") {
                        save()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else {
            return
        }

        errorMessage = nil

        if let playlistToEdit {
            rename(playlistToEdit)
        } else {
            createPlaylist()
        }
    }

    private func rename(_ playlist: PlaylistNode) {
        let originalName = playlist.name
        playlist.name = trimmedName

        do {
            try modelContext.save()
            dismiss()
        } catch {
            playlist.name = originalName
            errorMessage = "Could not rename playlist: \(error.localizedDescription)"
        }
    }

    private func createPlaylist() {
        let playlist = PlaylistNode(
            name: trimmedName,
            sortIndex: nextSortIndex
        )

        modelContext.insert(playlist)
        playlist.parent = parent

        do {
            try modelContext.save()
            dismiss()
        } catch {
            playlist.parent = nil
            modelContext.delete(playlist)

            errorMessage = "Could not create playlist: \(error.localizedDescription)"
        }
    }
}
