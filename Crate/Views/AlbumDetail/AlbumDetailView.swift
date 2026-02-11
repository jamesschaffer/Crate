import SwiftUI
import SwiftData
import MusicKit

/// Full album detail screen: large artwork, metadata, track list, and playback controls.
struct AlbumDetailView: View {

    let album: CrateAlbum

    @State private var viewModel = AlbumDetailViewModel()
    @State private var colorExtractor = ArtworkColorExtractor()
    @Environment(PlaybackViewModel.self) private var playbackViewModel
    @Environment(\.modelContext) private var modelContext

    /// Whether the currently playing album matches this one.
    private var isPlayingThisAlbum: Bool {
        playbackViewModel.nowPlayingAlbum?.id == album.id
    }

    var body: some View {
        // Read stateChangeCounter so play/pause state updates reactively.
        let _ = playbackViewModel.stateChangeCounter

        ZStack {
            // Blurred album art background
            AlbumArtworkView(artwork: album.artwork, size: 400, artworkURL: album.artworkURL, cornerRadius: 0)
                .scaleEffect(3)
                .blur(radius: 60)
                .ignoresSafeArea()

            // Dimming overlay — separate layer so it fills the full screen
            Color(.systemBackground)
                .opacity(0.5)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Album artwork with like/dislike in gutters
                    HStack {
                        Button {
                            viewModel.toggleDislike()
                        } label: {
                            Image(systemName: viewModel.isDisliked ? "xmark.circle.fill" : "xmark.circle")
                                .font(.title2)
                                .foregroundStyle(viewModel.isDisliked ? .gray : .primary)
                                .frame(width: 44, height: 44)
                        }

                        AlbumArtworkView(artwork: album.artwork, size: 280, artworkURL: album.artworkURL)
                            .shadow(radius: 8)

                        Button {
                            viewModel.toggleFavorite()
                        } label: {
                            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundStyle(viewModel.isFavorite ? .red : .primary)
                                .frame(width: 44, height: 44)
                        }
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

                    // Transport controls: prev — play/pause — next
                    HStack(spacing: 40) {
                        Button {
                            Task { await playbackViewModel.skipToPrevious() }
                        } label: {
                            Image(systemName: "backward.fill")
                                .font(.title2)
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
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
                                .background(colorExtractor.colors.0)
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
                        .buttonStyle(.plain)
                        .disabled(!playbackViewModel.hasQueue)
                    }
                    .padding(.vertical, 4)

                    // Track list
                    if viewModel.isLoading {
                        LoadingView(message: "Loading tracks...")
                    } else if let tracks = viewModel.tracks {
                        TrackListView(tracks: tracks, album: album, tintColor: colorExtractor.colors.0)
                    } else if let error = viewModel.errorMessage {
                        EmptyStateView(title: "Error", message: error)
                    }
                }
                .padding(12)
            }
        }
        .navigationTitle(album.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadAlbum(album)
            await colorExtractor.extract(from: album.artwork)
        }
    }
}

#Preview {
    NavigationStack {
        Text("Album Detail Preview")
    }
}
