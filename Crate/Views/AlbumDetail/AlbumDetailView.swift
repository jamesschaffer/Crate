import SwiftUI
import MusicKit

/// Full album detail screen: large artwork, metadata, track list, and playback controls.
struct AlbumDetailView: View {

    let album: CrateAlbum

    @State private var viewModel = AlbumDetailViewModel()
    @Environment(PlaybackViewModel.self) private var playbackViewModel

    /// Whether the currently playing album matches this one.
    private var isPlayingThisAlbum: Bool {
        playbackViewModel.nowPlayingAlbum?.id == album.id
    }

    var body: some View {
        // Read stateChangeCounter so play/pause state updates reactively.
        let _ = playbackViewModel.stateChangeCounter

        ScrollView {
            VStack(spacing: 16) {
                // Album artwork with favorite heart overlay
                AlbumArtworkView(artwork: album.artwork, size: 280, artworkURL: album.artworkURL)
                    .shadow(radius: 8)
                    .overlay(alignment: .topTrailing) {
                        Button {
                            Task {
                                await viewModel.toggleFavorite()
                            }
                        } label: {
                            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundStyle(viewModel.isFavorite ? .red : .white)
                                .shadow(radius: 4)
                                .frame(width: 44, height: 44)
                        }
                        .padding(8)
                    }

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

                // Transport controls: prev — play/pause — next
                HStack(spacing: 40) {
                    Button {
                        Task { await playbackViewModel.skipToPrevious() }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                    .disabled(!playbackViewModel.hasQueue)

                    Button {
                        Task {
                            if isPlayingThisAlbum {
                                await playbackViewModel.togglePlayPause()
                            } else if let tracks = viewModel.tracks {
                                playbackViewModel.nowPlayingAlbum = album
                                await playbackViewModel.play(tracks: tracks)
                            }
                        }
                    } label: {
                        Image(systemName: isPlayingThisAlbum && playbackViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title)
                            .frame(width: 64, height: 64)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.tracks == nil)

                    Button {
                        Task { await playbackViewModel.skipToNext() }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                    .disabled(!playbackViewModel.hasQueue)
                }
                .padding(.vertical, 4)

                Divider()
                    .padding(.horizontal)

                // Track list
                if viewModel.isLoading {
                    LoadingView(message: "Loading tracks...")
                } else if let tracks = viewModel.tracks {
                    TrackListView(tracks: tracks, album: album)
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
