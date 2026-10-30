import SwiftUI
import SwiftData

private struct TrackActionsModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext

    let track: PlaylistTrack

    @State private var errorMessage: String?

    private var orderedTracks: [PlaylistTrack] {
        guard let playlist = track.playlist else {
            return []
        }

        return playlist.tracks.sorted { first, second in
            if first.sortIndex != second.sortIndex {
                return first.sortIndex < second.sortIndex
            }

            return first.id.uuidString < second.id.uuidString
        }
    }

    private var currentIndex: Int? {
        orderedTracks.firstIndex { $0.id == track.id }
    }

    private var canMoveUp: Bool {
        guard let index = currentIndex else {
            return false
        }

        return index > 0
    }

    private var canMoveDown: Bool {
        guard let index = currentIndex else {
            return false
        }

        return index < orderedTracks.count - 1
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
            }
            .alert(
                "Could Not Reorder Song",
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

    private func reorder(_ direction: ReorderDirection) {
        do {
            try withAnimation {
                try TrackEditingService.reorder(
                    track,
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
    func trackActions(for track: PlaylistTrack) -> some View {
        modifier(
            TrackActionsModifier(track: track)
        )
    }
}
