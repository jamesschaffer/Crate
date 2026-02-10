import SwiftUI

/// Infinite-scroll grid of album cover tiles.
///
/// Always displays as edge-to-edge artwork wall (no spacing, no text labels).
/// When the user scrolls near the bottom, triggers onLoadMore to fetch the next page.
struct AlbumGridView: View {

    let albums: [CrateAlbum]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    var topInset: CGFloat = 0

    private var columns: [GridItem] {
        #if os(iOS)
        return [
            GridItem(.flexible(), spacing: 0),
            GridItem(.flexible(), spacing: 0),
        ]
        #else
        return [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 0)]
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Color.black
                    .frame(height: topInset)

                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(albums) { album in
                        NavigationLink(value: album) {
                            WallGridItemView(album: album)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if album == albums.last {
                                onLoadMore()
                            }
                        }
                    }
                }

                if isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
        }
        .background(.black)
    }
}

#Preview {
    NavigationStack {
        AlbumGridView(
            albums: [],
            isLoadingMore: false,
            onLoadMore: {}
        )
    }
}
