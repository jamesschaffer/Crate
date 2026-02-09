import SwiftUI
import MusicKit

/// Persistent mini-player bar that appears at the bottom of the screen
/// when something is in the playback queue.
///
/// Shows: current track artwork (small), track title, artist, play/pause, skip.
struct PlaybackFooterView: View {

    @Environment(PlaybackViewModel.self) private var viewModel

    var body: some View {
        // Read stateChangeCounter to trigger re-renders on player state changes.
        let _ = viewModel.stateChangeCounter

        HStack(spacing: 12) {
            // Small artwork
            if let artwork = viewModel.currentTrack?.artwork {
                ArtworkImage(artwork, width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 44, height: 44)
            }

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentTrack?.title ?? "Not Playing")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(viewModel.currentTrack?.artistName ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Transport controls
            HStack(spacing: 16) {
                Button {
                    Task { await viewModel.skipToPrevious() }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.body)
                }

                Button {
                    Task { await viewModel.togglePlayPause() }
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                }

                Button {
                    Task { await viewModel.skipToNext() }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.body)
                }
            }
            .foregroundStyle(.primary)
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
