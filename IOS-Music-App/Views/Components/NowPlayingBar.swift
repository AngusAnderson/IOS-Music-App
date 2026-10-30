import SwiftUI
import MusicKit

struct NowPlayingBar: View {
    
    @EnvironmentObject private var playback: PlaybackService
    
    @ObservedObject private var queue = ApplicationMusicPlayer.shared.queue
    @ObservedObject private var playerState = ApplicationMusicPlayer.shared.state
    
    var body: some View {
        if let entry = queue.currentEntry {
            HStack(spacing: 12) {
                // Artwork
                if let artwork = entry.artwork {
                    ArtworkImage(
                        artwork,
                        width: 48,
                        height: 48
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "music.note")
                        .frame(width: 48, height: 48)
                        .backgroundStyle(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Title and artist subtitle
                VStack(alignment: .leading, spacing: 4) {
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
                
                Spacer(minLength: 8)
                
                Button {
                    Task {
                        await playback.togglePlayback()
                    }
                } label: {
                    Image(
                        systemName: playerState.playbackStatus == .playing
                            ? "pause.fill"
                            : "play.fill"
                    )
                    .font(.title2)
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(playerState.playbackStatus == .playing ? "Pause" : "Resume")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .backgroundStyle(.regularMaterial)
        }
    }
}
