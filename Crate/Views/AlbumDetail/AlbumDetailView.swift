import SwiftUI
import MusicKit

/// Full album detail screen: large artwork, metadata, track list, and favorite button.
struct AlbumDetailView: View {

    let album: CrateAlbum

    @State private var viewModel = AlbumDetailViewModel()
    @Environment(PlaybackViewModel.self) private var playbackViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Album artwork
                AlbumArtworkView(artwork: album.artwork, size: 280, artworkURL: album.artworkURL)
                    .shadow(radius: 8)

                // Title and artist
                VStack(spacing: 4) {
                    Text(album.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(album.artistName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Genre tags
                if !album.genreNames.isEmpty {
                    HStack {
                        ForEach(album.genreNames, id: \.self) { genre in
                            Text(genre)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                // Action buttons
                HStack(spacing: 20) {
                    // Play button
                    Button {
                        Task {
                            if let tracks = viewModel.tracks {
                                await playbackViewModel.play(tracks: tracks)
                            }
                        }
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .disabled(viewModel.tracks == nil)

                    // Favorite button
                    Button {
                        Task {
                            await viewModel.toggleFavorite()
                        }
                    } label: {
                        Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundStyle(viewModel.isFavorite ? .red : .secondary)
                    }
                }

                Divider()
                    .padding(.horizontal)

                // Track list
                if viewModel.isLoading {
                    LoadingView(message: "Loading tracks...")
                } else if let tracks = viewModel.tracks {
                    TrackListView(tracks: tracks)
                } else if let error = viewModel.errorMessage {
                    EmptyStateView(title: "Error", message: error)
                }
            }
            .padding()
        }
        .navigationTitle(album.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await viewModel.loadAlbum(album)
        }
    }
}

#Preview {
    NavigationStack {
        Text("Album Detail Preview")
    }
}
