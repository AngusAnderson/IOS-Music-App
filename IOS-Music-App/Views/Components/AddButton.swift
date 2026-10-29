import SwiftUI

struct AddButton: View {
    
    @Binding var showPlaylistEditorSheet: Bool
    
    var body: some View {
        Button {
            showPlaylistEditorSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel("Open PlaylistEditorSheet")
    }
}
