import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation

private struct PlaylistDragDropModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext

    let node: PlaylistNode

    @State private var isTargeted = false
    @State private var errorMessage: String?

    private static let payloadPrefix = "playlisttree-node:"

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isTargeted
                            ? Color.accentColor.opacity(0.15)
                            : Color.clear
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isTargeted
                            ? Color.accentColor
                            : Color.clear,
                        lineWidth: 2
                    )
            }
            .onDrag {
                let payload =
                    Self.payloadPrefix + node.id.uuidString

                print("Drag started:", node.name)

                return NSItemProvider(
                    object: payload as NSString
                )
            }
            .onDrop(
                of: [UTType.text],
                isTargeted: $isTargeted
            ) { providers in
                receiveDrop(providers)
            }
            .alert(
                "Could Not Move Playlist",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { presented in
                        if !presented {
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

    private func receiveDrop(
        _ providers: [NSItemProvider]
    ) -> Bool {
        print("Drop received on:", node.name)

        guard
            providers.count == 1,
            let provider = providers.first,
            provider.canLoadObject(ofClass: NSString.self)
        else {
            print("Drop rejected: unsupported provider")
            return false
        }

        provider.loadObject(ofClass: NSString.self) { object, error in
            let payload = (object as? NSString).map { String($0) }
            let loadingError = error?.localizedDescription

            Task { @MainActor in
                if let loadingError {
                    errorMessage = loadingError
                    return
                }

                guard let payload else {
                    errorMessage = "The dragged playlist could not be read."
                    return
                }

                movePlaylist(from: payload)
            }
        }

        return true
    }

    @MainActor
    private func movePlaylist(from payload: String) {
        guard payload.hasPrefix(Self.payloadPrefix) else {
            print("Drop ignored: unrelated text")
            return
        }

        let rawID = String(
            payload.dropFirst(Self.payloadPrefix.count)
        )

        guard let draggedID = UUID(uuidString: rawID) else {
            errorMessage = "The dragged playlist ID is invalid."
            return
        }

        do {
            let descriptor = FetchDescriptor<PlaylistNode>(
                predicate: #Predicate<PlaylistNode> { candidate in
                    candidate.id == draggedID
                }
            )

            guard let draggedNode = try modelContext
                .fetch(descriptor)
                .first
            else {
                errorMessage = "The dragged playlist was not found."
                return
            }

            guard PlaylistEditingService.canMove(
                draggedNode,
                to: node
            ) else {
                print(
                    "Invalid move:",
                    draggedNode.name,
                    "→",
                    node.name
                )

                errorMessage = """
                This playlist cannot be moved into itself, \
                one of its descendants, or its existing parent.
                """
                return
            }

            try PlaylistEditingService.move(
                draggedNode,
                to: node,
                in: modelContext
            )

            print("Moved:", draggedNode.name, "into:", node.name)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

extension View {
    func playlistDragAndDrop(
        for node: PlaylistNode
    ) -> some View {
        modifier(
            PlaylistDragDropModifier(node: node)
        )
    }
}
