import SwiftUI
import MusicKit

struct PlaybackQueueView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var playback: PlaybackService

    @ObservedObject private var queue =
        ApplicationMusicPlayer.shared.queue

    @ObservedObject private var playerState =
        ApplicationMusicPlayer.shared.state

    private var upcomingEntries: [MusicPlayer.Queue.Entry] {
        let entries = Array(queue.entries)

        guard
            let currentEntry = queue.currentEntry,
            let currentIndex = entries.firstIndex(
                where: { $0.id == currentEntry.id }
            )
        else {
            return []
        }

        return Array(entries.dropFirst(currentIndex + 1))
    }

    var body: some View {
        NavigationStack {
            List {
                if let currentEntry = queue.currentEntry {
                    Section("Now Playing") {
                        queueRow(
                            currentEntry,
                            isCurrent: true
                        )

                        playbackControls
                    }

                    Section("Up Next") {
                        if upcomingEntries.isEmpty {
                            Text("No more songs in the queue.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(upcomingEntries) { entry in
                                queueRow(entry)
                            }
                        }
                    }
                } else {
                    Section {
                        ContentUnavailableView(
                            "Nothing Playing",
                            systemImage: "music.note.list",
                            description: Text(
                                "Start a playlist to see its playback queue."
                            )
                        )
                    }
                }

                if let errorMessage = playback.errorMessage {
                    Section("Playback Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if playback.skippedTrackCount > 0 {
                    Section {
                        Text(
                            "\(playback.skippedTrackCount) track(s) "
                            + "could not be included."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Playback Queue")
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

    // MARK: - Playback controls

    private var playbackControls: some View {
        HStack {
            Spacer()

            Button {
                Task {
                    await playback.skipToPrevious()
                }
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous track")

            Spacer()

            Button {
                Task {
                    await playback.togglePlayback()
                }
            } label: {
                Image(
                    systemName: playerState.playbackStatus == .playing
                        ? "pause.circle.fill"
                        : "play.circle.fill"
                )
                .font(.system(size: 48))
                .frame(width: 60, height: 60)
            }
            .accessibilityLabel(
                playerState.playbackStatus == .playing
                    ? "Pause"
                    : "Resume"
            )

            Spacer()

            Button {
                Task {
                    await playback.skipToNext()
                }
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next track")

            Spacer()
        }
        .buttonStyle(.borderless)
        .disabled(playback.isLoading)
    }

    // MARK: - Queue entry row

    private func queueRow(
        _ entry: MusicPlayer.Queue.Entry,
        isCurrent: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            if let artwork = entry.artwork {
                ArtworkImage(
                    artwork,
                    width: 52,
                    height: 52
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
            } else {
                Image(systemName: "music.note")
                    .frame(width: 52, height: 52)
                    .background(.quaternary)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 8)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .lineLimit(2)

                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isCurrent {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Current track")
            }
        }
        .padding(.vertical, 4)
    }
}
