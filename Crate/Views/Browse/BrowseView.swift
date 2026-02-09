import SwiftUI

/// Main browse screen: full-bleed album art with floating Liquid Glass controls.
///
/// Layout (ZStack):
/// - Background: Edge-to-edge album grid extending behind status bar
/// - Foreground (bottom): Settings gear, subcategory bar (conditional), genre bar
struct BrowseView: View {

    @State private var viewModel = BrowseViewModel()
    @State private var wallViewModel = CrateWallViewModel()
    @State private var showingSettings = false
    @State private var overlayHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background layer: full-bleed album grid
            gridContent
                .ignoresSafeArea(edges: .top)

            // Foreground layer: floating glass controls
            VStack(spacing: 8) {
                // Settings gear — right-aligned
                HStack {
                    Spacer()
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .padding(.trailing, 16)
                }

                // Subcategory bar (when genre selected)
                if viewModel.selectedCategory != nil {
                    SubCategoryBarView(
                        subcategories: viewModel.selectedCategory!.subcategories,
                        selectedIDs: viewModel.selectedSubcategoryIDs,
                        onToggle: { subcategoryID in
                            Task {
                                await viewModel.toggleSubcategory(subcategoryID)
                            }
                        }
                    )
                }

                // Genre bar (always visible)
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
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { overlayHeight = geo.size.height }
                        .onChange(of: geo.size.height) { _, newHeight in
                            overlayHeight = newHeight
                        }
                }
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task {
            await wallViewModel.generateWallIfNeeded()
        }
    }

    // MARK: - Grid Content

    @ViewBuilder
    private var gridContent: some View {
        if viewModel.selectedCategory == nil {
            wallContent
        } else {
            genreBrowseContent
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
                bottomPadding: overlayHeight
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
                },
                bottomPadding: overlayHeight
            )
        }
    }
}

#Preview {
    NavigationStack {
        BrowseView()
    }
}
