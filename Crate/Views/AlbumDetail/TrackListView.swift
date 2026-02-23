import SwiftUI
import MusicKit

/// Displays a numbered list of tracks for an album. Tapping a track
/// starts playback from that position.
struct TrackListView: View {

    let tracks: MusicItemCollection<Track>
    var album: CrateAlbum? = nil
    var tintColor: Color = .brandPink

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                TrackRow(
                    track: track,
                    index: index,
                    tracks: tracks,
                    album: album,
                    tintColor: tintColor,
                    isLast: index == tracks.count - 1
                )
            }
        }
    }
}

/// Single track row with isolated stateChangeCounter observation.
/// Only this row re-renders on player state changes — not the parent ForEach.
private struct TrackRow: View {

    let track: Track
    let index: Int
    let tracks: MusicItemCollection<Track>
    var album: CrateAlbum?
    var tintColor: Color
    var isLast: Bool

    @Environment(PlaybackViewModel.self) private var playbackViewModel

    var body: some View {
        let _ = playbackViewModel.stateChangeCounter

        Button {
            Task {
                await playbackViewModel.play(tracks: tracks, startingAt: index, from: album)
            }
        } label: {
            HStack(spacing: 8) {
                if isCurrentlyPlaying {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(tintColor)
                        .frame(width: 16, alignment: .trailing)
                        .padding(.trailing, 8)
                } else {
                    Text("\(index + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondaryText)
                        .frame(width: 16, alignment: .trailing)
                        .padding(.trailing, 8)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.body)
                        .lineLimit(1)

                    if !track.artistName.isEmpty {
                        Text(track.artistName)
                            .font(.footnote)
                            .foregroundStyle(.secondaryText)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let duration = track.duration {
                    Text(formattedDuration(duration))
                        .font(.footnote)
                        .foregroundStyle(.secondaryText)
                }
            }
            .padding(.vertical, 8)
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if !isLast {
            Divider()
                .padding(.leading, 6)
                .padding(.trailing, 12)
        }
    }

    private var isCurrentlyPlaying: Bool {
        guard playbackViewModel.isPlaying,
              let album,
              playbackViewModel.nowPlayingAlbum?.id == album.id,
              playbackViewModel.nowPlayingTitle == track.title else {
            return false
        }
        return true
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

#Preview {
    Text("Track list preview requires MusicKit data")
}
