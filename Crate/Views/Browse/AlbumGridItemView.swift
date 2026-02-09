import SwiftUI
import MusicKit

/// A single album cover tile in the grid. Shows artwork with the album
/// title and artist name below.
struct AlbumGridItemView: View {

    let album: CrateAlbum

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            AlbumArtworkView(artwork: album.artwork, size: 160)

            Text(album.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(album.artistName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// Preview requires a real MusicKit Album which can't be constructed in previews.
// Use the app running on a physical device to test this view.
