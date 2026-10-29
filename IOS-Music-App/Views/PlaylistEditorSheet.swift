import SwiftUI
import SwiftData

struct PlaylistEditorSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allNodes: [PlaylistNode]
    
    let parent: PlaylistNode?
    
    @State private var name: String = ""
    @State private var errorMessage: String?
    
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
                    TextField("e.g. Heavy", text: $name)
                        .textInputAutocapitalization(.words)
                        .onSubmit {
                            if !trimmedName.isEmpty {
                                createPlaylist()
                            }
                        }
                }
                
                Section("Location") {
                    Label(
                        parent?.name ?? "Your Library",
                        systemImage: parent == nil
                        ? "music.note.house"
                        : "music.note.list"
                    )
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPlaylist()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }
    
    private func createPlaylist() {
        guard !trimmedName.isEmpty else { return }
        
        errorMessage = nil
        
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
            
            errorMessage = "Could not save the playlist. \(error.localizedDescription)"
        }
    }
}
