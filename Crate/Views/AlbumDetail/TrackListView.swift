import SwiftUI
import MusicKit

/// Displays a numbered list of tracks for an album. Tapping a track
/// starts playback from that position.
struct TrackListView: View {

    let tracks: MusicItemCollection<Track>

    @Environment(PlaybackViewModel.self) private var playbackViewModel

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                Button {
                    Task {
                        await playbackViewModel.play(tracks: tracks, startingAt: index)
                    }
                } label: {
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, alignment: .trailing)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.body)
                                .lineLimit(1)

                            if !track.artistName.isEmpty {
                                Text(track.artistName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if let duration = track.duration {
                            Text(formattedDuration(duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < tracks.count - 1 {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
    }

    /// Format a TimeInterval (seconds) into "m:ss" string.
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

#Preview {
    Text("Track list preview requires MusicKit data")
}
