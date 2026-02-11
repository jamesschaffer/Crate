import SwiftUI
import SwiftData

/// Main browse screen: full-bleed album art with a unified control bar at the bottom.
///
/// The control bar is always visible and contains (top to bottom):
/// 1. Playback row — artwork, track info, play/pause (only when playing)
/// 2. Filter row — dial label + genre pills, or selected genre ✕ + subcategories
struct BrowseView: View {

    @State private var viewModel = BrowseViewModel()
    @State private var wallViewModel = CrateWallViewModel()
    @State private var coordinator = GridTransitionCoordinator()
    @State private var showingSettings = false
    @State private var dialStore = CrateDialStore()
    @Environment(PlaybackViewModel.self) private var playbackViewModel
    @Environment(\.modelContext) private var modelContext

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
            SettingsView(onDialChanged: {
                Task {
                    await wallViewModel.regenerate()
                }
            })
            .presentationDetents([.medium])
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            viewModel.loadDislikedIDs()
            wallViewModel.updateExcludedAlbums(viewModel.dislikedAlbumIDs)
            await wallViewModel.generateWallIfNeeded()
        }
        .environment(coordinator)
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
                dialLabel: dialStore.position.label,
                categories: GenreTaxonomy.categories,
                selectedCategory: viewModel.selectedCategory,
                onSelect: { category in
                    coordinator.transition(from: currentAlbums) {
                        await viewModel.selectCategory(category)
                        return viewModel.albums
                    }
                },
                onDialTap: {
                    showingSettings = true
                },
                onHome: {
                    coordinator.transition(from: currentAlbums) {
                        viewModel.clearSelection()
                        return wallViewModel.albums
                    }
                },
                selectedSubcategoryIDs: viewModel.selectedSubcategoryIDs,
                onToggleSubcategory: { id in
                    coordinator.transition(from: currentAlbums) {
                        await viewModel.toggleSubcategory(id)
                        return viewModel.albums
                    }
                },
                isDisabled: coordinator.isTransitioning
            )
        }
        .background(.ultraThinMaterial.opacity(0.85))
    }

    // MARK: - Playback Row

    private var playbackRow: some View {
        PlaybackRowContent()
            .padding(.horizontal)
            .padding(.vertical, 8)
    }

    // MARK: - Current Albums (reads from coordinator during transition, VMs during idle)

    private var currentAlbums: [CrateAlbum] {
        switch coordinator.phase {
        case .idle:
            return viewModel.selectedCategory == nil
                ? wallViewModel.albums
                : viewModel.albums
        case .exiting, .waiting, .entering:
            return coordinator.displayAlbums
        }
    }

    private var currentIsLoadingMore: Bool {
        viewModel.selectedCategory == nil
            ? wallViewModel.isLoadingMore
            : viewModel.isLoadingMore
    }

    // MARK: - Grid Content (single path — always mounted)

    private func gridContent(topInset: CGFloat) -> some View {
        ZStack {
            // Always-mounted grid
            AlbumGridView(
                albums: currentAlbums,
                isLoadingMore: currentIsLoadingMore,
                onLoadMore: {
                    Task {
                        if viewModel.selectedCategory == nil {
                            await wallViewModel.fetchMoreIfNeeded()
                        } else {
                            await viewModel.fetchNextPageIfNeeded()
                        }
                    }
                },
                topInset: topInset,
                scrollToTopTrigger: coordinator.scrollToTopTrigger
            )

            // Overlay states
            overlayContent
        }
    }

    // MARK: - Overlay States

    @ViewBuilder
    private var overlayContent: some View {
        if coordinator.showWaitingSpinner {
            // Transition waiting spinner
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black)
        } else if !coordinator.isTransitioning {
            // Only show loading/error/empty states during idle
            if viewModel.selectedCategory == nil {
                wallOverlay
            } else {
                genreOverlay
            }
        }
    }

    @ViewBuilder
    private var wallOverlay: some View {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        } else if wallViewModel.albums.isEmpty {
            EmptyStateView(
                title: "Your crate is empty",
                message: "We couldn't find any albums. Try again later."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        }
    }

    @ViewBuilder
    private var genreOverlay: some View {
        if viewModel.isLoading {
            LoadingView(message: "Loading albums...")
        } else if let error = viewModel.errorMessage {
            EmptyStateView(
                title: "Something went wrong",
                message: error
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        } else if viewModel.albums.isEmpty && viewModel.selectedCategory != nil {
            EmptyStateView(
                title: "No albums found",
                message: "Try selecting a different genre or subcategory."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.black)
        }
    }
}

#Preview {
    NavigationStack {
        BrowseView()
    }
    .environment(PlaybackViewModel())
}
