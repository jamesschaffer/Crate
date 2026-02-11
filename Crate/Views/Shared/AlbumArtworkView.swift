import SwiftUI
import MusicKit

/// Reusable album artwork component that handles the MusicKit Artwork type,
/// a raw artwork URL string, or a placeholder fallback.
///
/// Priority: MusicKit Artwork > artworkURL string > placeholder.
struct AlbumArtworkView: View {

    let artwork: Artwork?
    let size: CGFloat
    var artworkURL: String? = nil
    var cornerRadius: CGFloat? = nil
    @Environment(\.displayScale) private var displayScale

    /// Computed corner radius; callers can override via `cornerRadius`.
    private var radius: CGFloat {
        cornerRadius ?? (size > 100 ? 8 : 4)
    }

    var body: some View {
        if let artwork {
            ArtworkImage(artwork, width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: radius))
        } else if let urlString = artworkURL, let resolved = resolveURL(urlString) {
            AsyncImage(url: resolved) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: radius))
                default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.secondary.opacity(0.15))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.3))
                    .foregroundStyle(.secondaryText)
            }
    }

    /// Resolve an Apple Music artwork URL template by replacing `{w}` and `{h}`
    /// with the pixel size for the current display scale.
    private func resolveURL(_ template: String) -> URL? {
        let pixelSize = Int(size * displayScale)
        let resolved = template
            .replacingOccurrences(of: "{w}", with: "\(pixelSize)")
            .replacingOccurrences(of: "{h}", with: "\(pixelSize)")
        return URL(string: resolved)
    }
}

#Preview {
    VStack(spacing: 20) {
        AlbumArtworkView(artwork: nil, size: 200)
        AlbumArtworkView(artwork: nil, size: 80)
    }
}
