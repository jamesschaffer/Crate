import SwiftUI
import SwiftData
import MusicKit

/// Full album detail screen: large artwork, metadata, track list, and playback controls.
struct AlbumDetailView: View {

    let album: CrateAlbum
    var gridContext: GridContext?

    @State private var viewModel = AlbumDetailViewModel()
    @State private var colorExtractor = ArtworkColorExtractor()
    @Environment(PlaybackViewModel.self) private var playbackViewModel
    @Environment(\.modelContext) private var modelContext

    /// Platform-appropriate background color.
    private var backgroundColor: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    /// Whether the currently playing album matches this one.
    private var isPlayingThisAlbum: Bool {
        playbackViewModel.nowPlayingAlbum?.id == album.id
    }

    var body: some View {
        ZStack {
            // Blurred album art background
            AlbumArtworkView(artwork: album.artwork, size: 400, artworkURL: album.artworkURL, cornerRadius: 0)
                .scaleEffect(3)
                .blur(radius: 60)
                .ignoresSafeArea()

            // Dimming overlay — separate layer so it fills the full screen
            backgroundColor
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

                        NavigationLink(value: CrateDestination.artist(name: album.artistName, albumID: album.id)) {
                            Text(album.artistName)
                                .font(.title3)
                                .foregroundStyle(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Transport controls — isolated into child view so
                    // stateChangeCounter re-renders only the buttons,
                    // not the expensive blur background or scrubber.
                    AlbumTransportControls(
                        album: album,
                        tracks: viewModel.tracks,
                        accentColor: colorExtractor.hasExtracted ? colorExtractor.colors.0 : backgroundColor,
                        accentForeground: colorExtractor.hasExtracted ? .white : .primary
                    )

                    // Scrubber (only when playing this album)
                    if isPlayingThisAlbum {
                        PlaybackScrubber(gradientColors: colorExtractor.colors)
                            .transition(.opacity)
                    }

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
                .padding(.bottom, 80)
                .animation(.easeInOut(duration: 0.35), value: isPlayingThisAlbum)
            }
        }
        .navigationTitle(album.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            // Set grid context for auto-advance before any playback can start.
            if let gridContext {
                playbackViewModel.setGridContext(
                    gridAlbums: gridContext.albums,
                    tappedIndex: gridContext.tappedIndex
                )
            }
            viewModel.configure(modelContext: modelContext)
            await viewModel.loadAlbum(album)
            await colorExtractor.extract(from: album.artwork, artworkURL: album.artworkURL)
        }
    }
}

/// Isolates stateChangeCounter observation so only the transport buttons
/// re-render on playback state changes — not the entire AlbumDetailView
/// (which includes an expensive blur background).
/// Same pattern as PlaybackFooterOverlay in ContentView.
private struct AlbumTransportControls: View {

    let album: CrateAlbum
    let tracks: MusicItemCollection<Track>?
    let accentColor: Color
    let accentForeground: Color

    @Environment(PlaybackViewModel.self) private var playbackViewModel

    private var isPlayingThisAlbum: Bool {
        playbackViewModel.nowPlayingAlbum?.id == album.id
    }

    var body: some View {
        let _ = playbackViewModel.stateChangeCounter

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

            if playbackViewModel.isPreparingQueue {
                ProgressView()
                    .tint(accentForeground)
                    .frame(width: 64, height: 64)
                    .background(accentColor)
                    .clipShape(Circle())
            } else {
                Button {
                    Task {
                        if isPlayingThisAlbum {
                            await playbackViewModel.togglePlayPause()
                        } else if let tracks {
                            await playbackViewModel.play(tracks: tracks)
                            // Set nowPlayingAlbum after playback starts so the
                            // footer and scrubber don't appear during loading.
                            playbackViewModel.nowPlayingAlbum = album
                        }
                    }
                } label: {
                    Image(systemName: isPlayingThisAlbum && playbackViewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 64, height: 64)
                        .background(accentColor)
                        .foregroundStyle(accentForeground)
                        .clipShape(Circle())
                }
                .disabled(tracks == nil)
            }

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
    }
}

#Preview {
    NavigationStack {
        Text("Album Detail Preview")
    }
}
