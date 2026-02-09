import SwiftUI
import MusicKit

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

        HStack(spacing: 12) {
            // Tappable area: artwork + track info → navigates to album
            Button(action: onTap) {
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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

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
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

#Preview {
    PlaybackFooterView()
        .environment(PlaybackViewModel())
}
