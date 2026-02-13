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
    var scrollToTopTrigger: Bool = false
    var gridContext: [CrateAlbum]?

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
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id("grid-top")

                    Color.black
                        .frame(height: topInset)

                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                            NavigationLink(value: CrateDestination.album(
                                album,
                                gridContext: gridContext.map { GridContext(albums: $0, tappedIndex: index) }
                            )) {
                                AnimatedGridItemView(album: album, index: index)
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
                            .tint(.brandPink)
                            .padding()
                    }
                }
            }
            .background(.black)
            .onChange(of: scrollToTopTrigger) {
                withAnimation(nil) {
                    proxy.scrollTo("grid-top", anchor: .top)
                }
            }
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
