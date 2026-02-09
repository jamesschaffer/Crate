import SwiftUI

/// Main browse screen: Crate Wall (default) or genre-filtered browsing.
///
/// Layout (top to bottom):
/// 1. GenreBarView — "Crate" home pill + horizontal scroll of tier-1 super-genres
/// 2. SubCategoryBarView — tier-2 subcategories (when a genre is selected)
/// 3. Crate Wall grid (no genre selected) or genre album grid (genre selected)
struct BrowseView: View {

    @State private var viewModel = BrowseViewModel()
    @State private var wallViewModel = CrateWallViewModel()
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            GenreBarView(
                categories: GenreTaxonomy.categories,
                selectedCategory: viewModel.selectedCategory,
                onSelect: { category in
                    Task {
                        await viewModel.selectCategory(category)
                    }
                },
                onHome: {
                    viewModel.clearSelection()
                }
            )

            if let category = viewModel.selectedCategory {
                SubCategoryBarView(
                    subcategories: category.subcategories,
                    selectedIDs: viewModel.selectedSubcategoryIDs,
                    onToggle: { subcategoryID in
                        Task {
                            await viewModel.toggleSubcategory(subcategoryID)
                        }
                    }
                )
            }

            if viewModel.selectedCategory == nil {
                // Crate Wall mode
                wallContent
            } else {
                // Genre browse mode
                genreBrowseContent
            }
        }
        .navigationTitle("Crate")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task {
            await wallViewModel.generateWallIfNeeded()
        }
    }

    // MARK: - Crate Wall

    @ViewBuilder
    private var wallContent: some View {
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
                style: .wall
            )
        }
    }

    // MARK: - Genre Browse

    @ViewBuilder
    private var genreBrowseContent: some View {
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
                }
            )
        }
    }
}

#Preview {
    NavigationStack {
        BrowseView()
    }
}
