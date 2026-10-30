import SwiftUI
import SwiftData

struct MovePlaylistSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \PlaylistNode.sortIndex)
    private var allNodes: [PlaylistNode]

    let node: PlaylistNode

    @State private var currentFolder: PlaylistNode?
    @State private var errorMessage: String?

    init(node: PlaylistNode) {
        self.node = node

        self._currentFolder = State(
            initialValue: node.parent
        )
    }

    private var visibleFolders: [PlaylistNode] {
        allNodes.filter { candidate in
            guard candidate.parent?.id == currentFolder?.id else {
                return false
            }

            return candidate.id != node.id
        }
    }

    private var canMoveHere: Bool {
        PlaylistEditingService.canMove(
            node,
            to: currentFolder
        )
    }

    private var locationTitle: String {
        currentFolder?.name ?? "Your Library"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Moving “\(node.name)”")
                            .font(.headline)

                        Text(locationPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let folder = currentFolder {
                        Button {
                            currentFolder = folder.parent
                        } label: {
                            Label(
                                "Up One Level",
                                systemImage: "arrow.up"
                            )
                        }
                    }
                }

                Section("Folders in \(locationTitle)") {
                    if visibleFolders.isEmpty {
                        Text("No playlists in this location.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(visibleFolders) { folder in
                            Button {
                                currentFolder = folder
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "folder")
                                        .foregroundStyle(.tint)

                                    Text(folder.name)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    if canMoveHere {
                        Text(
                            "Move “\(node.name)” into \(locationTitle)."
                        )
                        .foregroundStyle(.secondary)
                    } else {
                        Text("This is the playlist’s current location.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Move Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Move Here") {
                        moveHere()
                    }
                    .disabled(!canMoveHere)
                }
            }
            .alert(
                "Could Not Move Playlist",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { isPresented in
                        if !isPresented {
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
    }

    private var locationPath: String {
        var names: [String] = []
        var current = currentFolder
        var visited = Set<UUID>()

        while let folder = current {
            guard visited.insert(folder.id).inserted else {
                break
            }

            names.append(folder.name)
            current = folder.parent
        }

        let components = ["Your Library"] + Array(names.reversed())
        return components.joined(separator: " / ")
    }

    private func moveHere() {
        do {
            try PlaylistEditingService.move(
                node,
                to: currentFolder,
                in: modelContext
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
