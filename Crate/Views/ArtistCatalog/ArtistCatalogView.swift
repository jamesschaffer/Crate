import SwiftUI
import MusicKit

/// Full-bleed grid of an artist's albums, sorted oldest-first.
struct ArtistCatalogView: View {

    let artistName: String
    let albumID: MusicItemID

    @State private var viewModel = ArtistCatalogViewModel()
    @State private var coordinator = GridTransitionCoordinator()
    @Environment(PlaybackViewModel.self) private var playbackViewModel

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                LoadingView(message: "Loading albums...")
            } else if let error = viewModel.errorMessage {
                EmptyStateView(title: "Something went wrong", message: error)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black)
            } else {
                AlbumGridView(
                    albums: viewModel.albums,
                    isLoadingMore: false,
                    onLoadMore: {},
                    onAlbumTapped: { index in
                        playbackViewModel.setGridContext(
                            gridAlbums: viewModel.albums,
                            tappedIndex: index
                        )
                    }
                )
            }
        }
        .background(.black)
        .environment(coordinator)
        .navigationTitle(artistName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await viewModel.load(albumID: albumID)
        }
    }
}
