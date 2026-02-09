import SwiftUI

/// Infinite-scroll grid of album cover tiles.
///
/// Displays albums in a multi-column grid. When the user scrolls near the
/// bottom, triggers onLoadMore to fetch the next page.
struct AlbumGridView: View {

    let albums: [CrateAlbum]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void

    /// Adaptive grid: fills as many columns as fit with a minimum width of 150pt.
    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(albums) { album in
                    NavigationLink(value: album) {
                        AlbumGridItemView(album: album)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        // Trigger pagination when the user reaches near the end.
                        if album == albums.last {
                            onLoadMore()
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if isLoadingMore {
                ProgressView()
                    .padding()
            }
        }
        .navigationDestination(for: CrateAlbum.self) { album in
            AlbumDetailView(album: album)
        }
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
