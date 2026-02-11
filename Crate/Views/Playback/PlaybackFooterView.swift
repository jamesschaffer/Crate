import SwiftUI
import MusicKit

/// Shared playback row content: artwork + track info + play/pause toggle.
/// Used by both PlaybackFooterView and BrowseView's control bar.
struct PlaybackRowContent: View {

    @Environment(PlaybackViewModel.self) private var viewModel
    var onTap: (() -> Void)? = nil

    var body: some View {
        // Read stateChangeCounter so play/pause icon updates reactively.
        // Needed because isPlaying reads from ApplicationMusicPlayer
        // which isn't tracked by @Observable.
        let _ = viewModel.stateChangeCounter

        HStack(spacing: 12) {
            // Tappable area: artwork + track info
            Group {
                if let onTap {
                    Button(action: onTap) { trackInfo.contentShape(Rectangle()) }
                        .buttonStyle(.plain)
                } else {
                    trackInfo
                }
            }

            // Play/pause toggle
            Button {
                Task { await viewModel.togglePlayPause() }
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
    }

    private var trackInfo: some View {
        HStack(spacing: 12) {
            if let artwork = viewModel.nowPlayingArtwork {
                ArtworkImage(artwork, width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.nowPlayingTitle ?? "Not Playing")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let subtitle = viewModel.nowPlayingSubtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
    }
}

/// Persistent mini-player bar at the bottom of the screen.
///
/// Shows current track artwork, title, artist, and a play/pause toggle.
/// Tapping anywhere outside the play/pause button triggers onTap (navigation).
struct PlaybackFooterView: View {

    @Environment(PlaybackViewModel.self) private var viewModel
    var onTap: () -> Void = {}

    var body: some View {
        // Read stateChangeCounter to trigger re-renders on player state changes.
        let _ = viewModel.stateChangeCounter

        VStack(spacing: 0) {
            PlaybackProgressBar()
            PlaybackRowContent(onTap: onTap)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }
}

#Preview {
    PlaybackFooterView()
        .environment(PlaybackViewModel())
}
