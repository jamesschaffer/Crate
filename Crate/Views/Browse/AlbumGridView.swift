import SwiftUI

/// Controls the visual layout of the album grid.
enum AlbumGridStyle {
    /// Edge-to-edge artwork wall with no spacing or text labels.
    case wall
    /// Standard browse layout with spacing, padding, and album info.
    case browse
}

/// Infinite-scroll grid of album cover tiles.
///
/// Displays albums in a multi-column grid. When the user scrolls near the
/// bottom, triggers onLoadMore to fetch the next page.
struct AlbumGridView: View {

    let albums: [CrateAlbum]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    var style: AlbumGridStyle = .browse

    private var columns: [GridItem] {
        switch style {
        case .wall:
            #if os(iOS)
            return [
                GridItem(.flexible(), spacing: 0),
                GridItem(.flexible(), spacing: 0),
            ]
            #else
            return [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 0)]
            #endif
        case .browse:
            return [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)]
        }
    }

    private var gridSpacing: CGFloat {
        style == .wall ? 0 : 12
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(albums) { album in
                    NavigationLink(value: album) {
                        gridItem(for: album)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if album == albums.last {
                            onLoadMore()
                        }
                    }
                }
            }
            .padding(.horizontal, style == .wall ? 0 : nil)
            .padding(.top, style == .wall ? 0 : 8)

            if isLoadingMore {
                ProgressView()
                    .padding()
            }
        }
        .navigationDestination(for: CrateAlbum.self) { album in
            AlbumDetailView(album: album)
        }
    }

    @ViewBuilder
    private func gridItem(for album: CrateAlbum) -> some View {
        switch style {
        case .wall:
            WallGridItemView(album: album)
        case .browse:
            AlbumGridItemView(album: album)
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
