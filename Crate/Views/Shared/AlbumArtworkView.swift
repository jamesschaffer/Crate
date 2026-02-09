import SwiftUI
import MusicKit

/// Reusable album artwork component that handles the MusicKit Artwork type.
///
/// Renders the artwork at the requested size with rounded corners.
/// Shows a placeholder when artwork is nil.
struct AlbumArtworkView: View {

    let artwork: Artwork?
    let size: CGFloat

    var body: some View {
        if let artwork {
            ArtworkImage(artwork, width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size > 100 ? 8 : 4))
        } else {
            // Placeholder when no artwork is available
            RoundedRectangle(cornerRadius: size > 100 ? 8 : 4)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.3))
                        .foregroundStyle(.secondary)
                }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AlbumArtworkView(artwork: nil, size: 200)
        AlbumArtworkView(artwork: nil, size: 80)
    }
}
