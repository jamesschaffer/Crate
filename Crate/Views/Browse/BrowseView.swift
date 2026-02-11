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
        PlaybackRowContent()
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
