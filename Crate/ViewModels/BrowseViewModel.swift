import Foundation
import MusicKit
import Observation
import SwiftData

/// Drives the main Browse screen: genre selection, album fetching, and pagination.
///
/// Two fetch strategies:
/// - **Parent genre** (no subcategories): multi-signal blended feed via GenreFeedService.
/// - **Subcategories selected**: search albums via `/search` endpoint, one query
///   per subcategory, merged and deduplicated.
@MainActor
@Observable
final class BrowseViewModel {

    // MARK: - Dependencies

    private let musicService: MusicServiceProtocol
    private let favoritesService: FavoritesService
    private let dislikeService: DislikeService
    private let dialStore: CrateDialStore

    // MARK: - Genre Selection State

    /// The currently selected top-level genre category.
    var selectedCategory: GenreCategory?

    /// Currently selected subcategory IDs (multi-select).
    var selectedSubcategoryIDs: Set<String> = []

    // MARK: - Album State

    /// Albums currently displayed in the grid.
    var albums: [CrateAlbum] = []

    /// True while fetching the first page.
    var isLoading: Bool = false

    /// True while fetching additional pages (infinite scroll).
    var isLoadingMore: Bool = false

    /// Set when a fetch fails.
    var errorMessage: String?

    /// Whether there are more albums to fetch.
    var hasMorePages: Bool = true

    // MARK: - Feed State

    /// IDs of albums already displayed, for dedup across pages.
    private var existingIDs: Set<MusicItemID> = []

    /// IDs of disliked albums, loaded once and passed to services.
    private(set) var dislikedAlbumIDs: Set<String> = []

    // MARK: - Pagination (subcategory search only)

    private let pageSize: Int = 25
    private var currentOffset: Int = 0

    // MARK: - Init

    init(musicService: MusicServiceProtocol = MusicService(),
         favoritesService: FavoritesService = FavoritesService(),
         dislikeService: DislikeService = DislikeService(),
         dialStore: CrateDialStore = CrateDialStore()) {
        self.musicService = musicService
        self.favoritesService = favoritesService
        self.dislikeService = dislikeService
        self.dialStore = dialStore
    }

    // MARK: - Configuration

    /// Inject the SwiftData model context into both services.
    /// Call this from the view layer before any CRUD operations.
    func configure(modelContext: ModelContext) {
        favoritesService.modelContext = modelContext
        dislikeService.modelContext = modelContext
    }

    // MARK: - Actions

    /// Load disliked album IDs (call once at view appear).
    func loadDislikedIDs() {
        dislikedAlbumIDs = dislikeService.fetchAllDislikedIDs()
    }

    /// Select a top-level genre category and fetch its albums.
    func selectCategory(_ category: GenreCategory) async {
        selectedCategory = category
        selectedSubcategoryIDs = []
        await resetAndFetch()
    }

    /// Toggle a subcategory on/off and run a fresh query.
    func toggleSubcategory(_ subcategoryID: String) async {
        if selectedSubcategoryIDs.contains(subcategoryID) {
            selectedSubcategoryIDs.remove(subcategoryID)
        } else {
            selectedSubcategoryIDs.insert(subcategoryID)
        }
        await resetAndFetch()
    }

    /// Clear the current selection and return to the wall (no genre selected).
    func clearSelection() {
        selectedCategory = nil
        selectedSubcategoryIDs = []
        albums = []
        existingIDs = []
        currentOffset = 0
        hasMorePages = true
        errorMessage = nil
    }

    /// Fetch the next page of albums (called when the user scrolls near the bottom).
    func fetchNextPageIfNeeded() async {
        guard !isLoadingMore, hasMorePages else { return }
        if !selectedSubcategoryIDs.isEmpty {
            await fetchSubcategoryAlbums(offset: currentOffset)
        } else {
            await fetchGenreFeedPage()
        }
    }

    // MARK: - Private

    /// Clear current albums and fetch from offset 0.
    private func resetAndFetch() async {
        albums = []
        existingIDs = []
        currentOffset = 0
        hasMorePages = true
        errorMessage = nil

        if !selectedSubcategoryIDs.isEmpty {
            await fetchSubcategoryAlbums(offset: 0)
        } else {
            await fetchGenreFeedInitial()
        }
    }

    // MARK: - Genre Feed (blended multi-signal)

    /// Build a GenreFeedService for the current genre and settings.
    private func makeGenreFeedService() -> GenreFeedService? {
        guard let genre = selectedCategory else { return nil }

        // Load seed albums (favorites matching this genre).
        let allFavorites = favoritesService.fetchAll()

        return GenreFeedService(
            genre: genre,
            musicService: musicService,
            dialStore: dialStore,
            excludedAlbumIDs: dislikedAlbumIDs,
            seedAlbums: allFavorites
        )
    }

    /// Fetch the initial genre feed (~50 albums).
    private func fetchGenreFeedInitial() async {
        guard let feedService = makeGenreFeedService() else {
            albums = []
            return
        }

        isLoading = true

        let feed = await feedService.generateFeed(total: 50, excluding: [])
        albums = feed
        existingIDs = Set(feed.map(\.id))
        hasMorePages = !feed.isEmpty

        isLoading = false
    }

    /// Fetch more genre feed albums for infinite scroll (~25 albums).
    private func fetchGenreFeedPage() async {
        guard let feedService = makeGenreFeedService() else { return }

        isLoadingMore = true

        let more = await feedService.generateFeed(total: 25, excluding: existingIDs)
        albums.append(contentsOf: more)
        existingIDs.formUnion(more.map(\.id))
        hasMorePages = !more.isEmpty

        isLoadingMore = false
    }

    // MARK: - Search Fetch (subcategories)

    /// Fetch albums by searching for each selected subcategory name.
    /// Runs queries in parallel via TaskGroup, merges and deduplicates results.
    private func fetchSubcategoryAlbums(offset: Int) async {
        let subcatNames = selectedSubcategoryIDs.compactMap {
            GenreTaxonomy.subcategory(withID: $0)?.name
        }
        guard !subcatNames.isEmpty else { return }

        if offset == 0 { isLoading = true } else { isLoadingMore = true }

        do {
            let perSubLimit = max(pageSize / subcatNames.count, 10)

            // Capture locally to avoid MainActor serialization in @Sendable closures.
            let service = musicService

            let allFetched = try await withThrowingTaskGroup(of: [CrateAlbum].self) { group in
                for name in subcatNames {
                    group.addTask {
                        try await service.searchAlbums(
                            term: name,
                            limit: perSubLimit,
                            offset: offset
                        )
                    }
                }
                var results: [CrateAlbum] = []
                for try await batch in group {
                    results.append(contentsOf: batch)
                }
                return results
            }

            // Deduplicate against existing albums and within the batch.
            // Also filter out disliked albums.
            let dislikedMusicIDs = Set(dislikedAlbumIDs.map { MusicItemID($0) })
            var seen = Set(albums.map(\.id)).union(dislikedMusicIDs)
            let unique = allFetched.filter { seen.insert($0.id).inserted }

            if offset == 0 { albums = unique } else { albums.append(contentsOf: unique) }
            hasMorePages = allFetched.count >= perSubLimit
            currentOffset = offset + perSubLimit
        } catch {
            errorMessage = "Failed to load albums: \(error.localizedDescription)"
        }

        isLoading = false
        isLoadingMore = false
    }
}
