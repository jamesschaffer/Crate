import Foundation
import MusicKit
import Observation

/// Drives the main Browse screen: genre selection, album fetching, and pagination.
///
/// Holds the currently selected genre category and subcategories, fetches chart
/// albums from MusicService, and manages an in-memory page cache so we don't
/// re-fetch pages the user has already scrolled through.
@Observable
final class BrowseViewModel {

    // MARK: - Dependencies

    private let musicService: MusicServiceProtocol
    private let genreService: GenreService

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

    // MARK: - Pagination

    private let pageSize: Int = 25
    private var currentOffset: Int = 0

    /// In-memory cache keyed by "\(genreID)-\(offset)" to avoid redundant fetches.
    private var pageCache: [String: [CrateAlbum]] = [:]

    // MARK: - Init

    init(musicService: MusicServiceProtocol = MusicService(),
         genreService: GenreService = GenreService()) {
        self.musicService = musicService
        self.genreService = genreService
    }

    // MARK: - Actions

    /// Select a top-level genre category and fetch its albums.
    func selectCategory(_ category: GenreCategory) async {
        selectedCategory = category
        selectedSubcategoryIDs = []
        await resetAndFetch()
    }

    /// Toggle a subcategory on/off and re-fetch albums.
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
        currentOffset = 0
        hasMorePages = true
        errorMessage = nil
    }

    /// Fetch the next page of albums (called when the user scrolls near the bottom).
    func fetchNextPageIfNeeded() async {
        guard !isLoadingMore, hasMorePages else { return }
        await fetchAlbums(offset: currentOffset)
    }

    // MARK: - Private

    /// Clear current albums and fetch from offset 0.
    private func resetAndFetch() async {
        albums = []
        currentOffset = 0
        hasMorePages = true
        errorMessage = nil
        await fetchAlbums(offset: 0)
    }

    /// Fetch a page of chart albums for the active genre filter.
    private func fetchAlbums(offset: Int) async {
        let genreID = activeGenreID
        guard let genreID else {
            albums = []
            return
        }

        let cacheKey = "\(genreID)-\(offset)"

        // Return cached page if available.
        if let cached = pageCache[cacheKey] {
            if offset == 0 {
                albums = cached
            } else {
                albums.append(contentsOf: cached)
            }
            currentOffset = offset + pageSize
            return
        }

        if offset == 0 {
            isLoading = true
        } else {
            isLoadingMore = true
        }

        do {
            let fetched = try await musicService.fetchChartAlbums(
                genreID: genreID,
                limit: pageSize,
                offset: offset
            )

            pageCache[cacheKey] = fetched

            if offset == 0 {
                albums = fetched
            } else {
                albums.append(contentsOf: fetched)
            }

            hasMorePages = fetched.count >= pageSize
            currentOffset = offset + pageSize
        } catch {
            errorMessage = "Failed to load albums: \(error.localizedDescription)"
        }

        isLoading = false
        isLoadingMore = false
    }

    /// Determine which Apple Music genre ID to use for the current filter state.
    /// If subcategories are selected, use the first one; otherwise use the parent category.
    private var activeGenreID: String? {
        if let firstSub = selectedSubcategoryIDs.first,
           let sub = GenreTaxonomy.subcategory(withID: firstSub) {
            return sub.appleMusicID
        }
        return selectedCategory?.appleMusicID
    }
}
