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
    @State private var showingImportSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(rootNodes) { node in
                        NavigationLink {
                            PlaylistDetailView(node: node)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder.fill")
                                    .foregroundStyle(.tint)

                                Text(node.name)
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
                        .playlistDragAndDrop(for: node)
                        .playlistActions(for: node)
                    }
                }
                .padding()
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label(
                            "Import Playlists",
                            systemImage: "square.and.arrow.down"
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
        .sheet(isPresented: $showingImportSheet) {
            ImportPlaylistsSheet()
        }
    }
}
