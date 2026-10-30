import SwiftUI
import MusicKit

struct NowPlayingBar: View {
    @EnvironmentObject private var playback: PlaybackService

    @ObservedObject private var queue =
        ApplicationMusicPlayer.shared.queue

    @ObservedObject private var playerState =
        ApplicationMusicPlayer.shared.state

    @State private var showingQueue = false

    var body: some View {
        Group {
            if let entry = queue.currentEntry {
                HStack(spacing: 12) {
                    Button {
                        showingQueue = true
                    } label: {
                        HStack(spacing: 12) {
                            if let artwork = entry.artwork {
                                ArtworkImage(
                                    artwork,
                                    width: 48,
                                    height: 48
                                )
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 8)
                                )
                            } else {
                                Image(systemName: "music.note")
                                    .frame(width: 48, height: 48)
                                    .background(.quaternary)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 8)
                                    )
                            }

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {
                                Text(entry.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)

                                if let subtitle = entry.subtitle {
                                    Text(subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the playback queue")

                    Button {
                        Task {
                            await playback.togglePlayback()
                        }
                    } label: {
                        Image(
                            systemName:
                                playerState.playbackStatus == .playing
                                ? "pause.fill"
                                : "play.fill"
                        )
                        .font(.title2)
                        .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        playerState.playbackStatus == .playing
                            ? "Pause"
                            : "Resume"
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.regularMaterial)
            }
        }
        .sheet(isPresented: $showingQueue) {
            PlaybackQueueView()
                .environmentObject(playback)
        }
    }
}
