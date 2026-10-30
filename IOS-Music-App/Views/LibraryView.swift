import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(
        filter: #Predicate<PlaylistNode> { node in
            node.parent == nil
        },
        sort: \PlaylistNode.sortIndex
    )
    private var rootNodes: [PlaylistNode]

    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            List(rootNodes) { node in
                NavigationLink {
                    PlaylistDetailView(node: node)
                } label: {
                    Label(
                        node.name,
                        systemImage: "music.note.list"
                    )
                }
            }
            .navigationTitle("Your library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label(
                            "Settings",
                            systemImage: "gearshape"
                        )
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            NowPlayingBar()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}
