import SwiftUI
import SwiftData

private struct PlaylistActionsModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \PlaylistNode.sortIndex)
    private var allNodes: [PlaylistNode]

    let node: PlaylistNode

    @State private var showingMoveSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var errorMessage: String?
    
    private var siblings: [PlaylistNode] {
        allNodes
            .filter { candidate in
                candidate.parent?.id == node.parent?.id
            }
            .sorted { first, second in
                if first.sortIndex != second.sortIndex {
                    return first.sortIndex < second.sortIndex
                }

                return first.id.uuidString < second.id.uuidString
            }
    }

    private var currentSiblingIndex: Int? {
        siblings.firstIndex { $0.id == node.id }
    }

    private var canMoveUp: Bool {
        guard let index = currentSiblingIndex else {
            return false
        }

        return index > 0
    }

    private var canMoveDown: Bool {
        guard let index = currentSiblingIndex else {
            return false
        }

        return index < siblings.count - 1
    }

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    reorder(.up)
                } label: {
                    Label("Move Up", systemImage: "arrow.up")
                }
                .disabled(!canMoveUp)

                Button {
                    reorder(.down)
                } label: {
                    Label("Move Down", systemImage: "arrow.down")
                }
                .disabled(!canMoveDown)

                Divider()

                Button {
                    showingMoveSheet = true
                } label: {
                    Label("Move to Folder", systemImage: "folder")
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
    
    private func reorder(_ direction: ReorderDirection) {
        do {
            try withAnimation {
                try PlaylistEditingService.reorder(
                    node,
                    direction: direction,
                    in: modelContext
                )
            }
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
