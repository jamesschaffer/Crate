import SwiftUI
import MusicKit

/// Artwork-only tile for the Crate Wall grid.
/// No text labels, no rounded corners — edge-to-edge album art.
struct WallGridItemView: View {

    let album: CrateAlbum

    var body: some View {
        GeometryReader { geo in
            AlbumArtworkView(
                artwork: album.artwork,
                size: geo.size.width,
                artworkURL: album.artworkURL,
                cornerRadius: 0
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
