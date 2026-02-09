import SwiftUI

/// Main browse screen: genre selection bars at the top, album grid below.
///
/// Layout (top to bottom):
/// 1. GenreBarView — horizontal scroll of tier-1 super-genres
/// 2. SubCategoryBarView — horizontal scroll of tier-2 subcategories (if a genre is selected)
/// 3. AlbumGridView — infinite-scroll grid of album covers
struct BrowseView: View {

    @State private var viewModel = BrowseViewModel()

    var body: some View {
        VStack(spacing: 0) {
            GenreBarView(
                categories: GenreTaxonomy.categories,
                selectedCategory: viewModel.selectedCategory,
                onSelect: { category in
                    Task {
                        await viewModel.selectCategory(category)
                    }
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
            } else if viewModel.albums.isEmpty {
                EmptyStateView(
                    title: "Pick a genre",
                    message: "Select a genre above to start browsing albums."
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
        .navigationTitle("Crate")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview {
    NavigationStack {
        BrowseView()
    }
}
