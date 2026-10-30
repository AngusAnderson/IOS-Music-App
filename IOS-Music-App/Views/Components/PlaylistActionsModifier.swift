import SwiftUI
import SwiftData

private struct PlaylistActionsModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext

    let node: PlaylistNode

    @State private var showingMoveSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    showingMoveSheet = true
                } label: {
                    Label("Move", systemImage: "folder")
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .sheet(isPresented: $showingMoveSheet) {
                MovePlaylistSheet(node: node)
            }
            .confirmationDialog(
                "Delete “\(node.name)”?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    "Delete from This App",
                    role: .destructive
                ) {
                    deletePlaylist()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "Its direct song entries will be removed. "
                    + "Child playlists will move to Your Library. "
                    + "The original Apple Music playlist will not be changed."
                )
            }
            .alert(
                "Could Not Delete Playlist",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: {
                        if !$0 {
                            errorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
    }

    private func deletePlaylist() {
        do {
            try PlaylistEditingService.deleteKeepingChildren(
                node,
                in: modelContext
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension View {
    func playlistActions(for node: PlaylistNode) -> some View {
        modifier(PlaylistActionsModifier(node: node))
    }
}
