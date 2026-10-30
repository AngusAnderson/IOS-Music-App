import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(PlaybackTraversal.storageKey)
    private var selectedTraversal: PlaybackTraversal = .depthFirst

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        "Traversal",
                        selection: $selectedTraversal
                    ) {
                        ForEach(
                            PlaybackTraversal.allCases,
                            id: \.self
                        ) { traversal in
                            Text(traversal.title)
                                .tag(traversal)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Playback Order")
                } footer: {
                    Text(
                        selectedTraversal.explanation
                        + "\n\nChanges apply when you start a new playlist. "
                        + "The current queue is not changed."
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
