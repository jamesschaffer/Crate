import SwiftUI
import MusicKit

/// Main browse screen: full-bleed album art with a unified control bar at the bottom.
///
/// The control bar is always visible and contains (top to bottom):
/// 1. Playback row — artwork, track info, play/pause (only when playing)
/// 2. Filter row — dial label + genre pills, or selected genre ✕ + subcategories
struct BrowseView: View {

    @State private var viewModel = BrowseViewModel()
    @State private var wallViewModel = CrateWallViewModel()
    @State private var showingSettings = false
    @Environment(PlaybackViewModel.self) private var playbackViewModel

    private var dialLabel: String {
        CrateDialStore().position.label
    }

    var body: some View {
        GeometryReader { geometry in
            gridContent(topInset: geometry.safeAreaInsets.top)
                .ignoresSafeArea(edges: .top)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    controlBar
                }
                .navigationDestination(for: CrateAlbum.self) { album in
                    AlbumDetailView(album: album)
                }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task {
            viewModel.loadDislikedIDs()
            wallViewModel.updateExcludedAlbums(viewModel.dislikedAlbumIDs)
            await wallViewModel.generateWallIfNeeded()
        }
    }

    // MARK: - Unified Control Bar

    private var controlBar: some View {
        // Read stateChangeCounter so playback row updates reactively.
        let _ = playbackViewModel.stateChangeCounter

        return VStack(spacing: 0) {
            // Playback row (when something is playing)
            if playbackViewModel.hasQueue {
                playbackRow
                Divider()
            }

            // Filter row (always visible, transforms between genres and subcategories)
            GenreBarView(
                dialLabel: dialLabel,
                categories: GenreTaxonomy.categories,
                selectedCategory: viewModel.selectedCategory,
                onSelect: { category in
                    Task {
                        await viewModel.selectCategory(category)
                    }
                },
                onDialTap: {
                    showingSettings = true
                },
                onHome: {
                    viewModel.clearSelection()
                },
                selectedSubcategoryIDs: viewModel.selectedSubcategoryIDs,
                onToggleSubcategory: { id in
                    Task { await viewModel.toggleSubcategory(id) }
                }
            )
        }
        .background(.ultraThinMaterial.opacity(0.85))
    }

    // MARK: - Playback Row

    private var playbackRow: some View {
        HStack(spacing: 12) {
            // Tappable area: artwork + track info
            HStack(spacing: 12) {
                if let artwork = playbackViewModel.nowPlayingArtwork {
                    ArtworkImage(artwork, width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 44, height: 44)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(playbackViewModel.nowPlayingTitle ?? "Not Playing")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if let subtitle = playbackViewModel.nowPlayingSubtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            // Play/pause toggle
            Button {
                Task { await playbackViewModel.togglePlayPause() }
            } label: {
                Image(systemName: playbackViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Grid Content

    @ViewBuilder
    private func gridContent(topInset: CGFloat) -> some View {
        if viewModel.selectedCategory == nil {
            wallContent(topInset: topInset)
        } else {
            genreBrowseContent(topInset: topInset)
        }
    }

    // MARK: - Crate Wall

    @ViewBuilder
    private func wallContent(topInset: CGFloat) -> some View {
        if wallViewModel.isLoading {
            LoadingView(message: "Building your crate...")
        } else if let error = wallViewModel.errorMessage {
            VStack(spacing: 16) {
                EmptyStateView(
                    title: "Something went wrong",
                    message: error
                )
                Button("Try Again") {
                    Task {
                        await wallViewModel.regenerate()
                    }
                }
                .buttonStyle(.bordered)
            }
        } else if wallViewModel.albums.isEmpty {
            EmptyStateView(
                title: "Your crate is empty",
                message: "We couldn't find any albums. Try again later."
            )
        } else {
            AlbumGridView(
                albums: wallViewModel.albums,
                isLoadingMore: wallViewModel.isLoadingMore,
                onLoadMore: {
                    Task {
                        await wallViewModel.fetchMoreIfNeeded()
                    }
                },
                topInset: topInset
            )
        }
    }

    // MARK: - Genre Browse

    @ViewBuilder
    private func genreBrowseContent(topInset: CGFloat) -> some View {
        if viewModel.isLoading {
            LoadingView(message: "Loading albums...")
        } else if let error = viewModel.errorMessage {
            EmptyStateView(
                title: "Something went wrong",
                message: error
            )
        } else if viewModel.albums.isEmpty && viewModel.selectedCategory != nil {
            EmptyStateView(
                title: "No albums found",
                message: "Try selecting a different genre or subcategory."
            )
        } else {
            AlbumGridView(
                albums: viewModel.albums,
                isLoadingMore: viewModel.isLoadingMore,
                onLoadMore: {
                    Task {
                        await viewModel.fetchNextPageIfNeeded()
                    }
                },
                topInset: topInset
            )
        }
    }
}

#Preview {
    NavigationStack {
        BrowseView()
    }
    .environment(PlaybackViewModel())
}
