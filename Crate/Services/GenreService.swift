import Foundation
import MusicKit

/// Coordinates between the static genre taxonomy and MusicService
/// for chart fetching. Provides lookup helpers so ViewModels don't
/// need to understand the taxonomy structure directly.
struct GenreService: Sendable {

    private let musicService: MusicServiceProtocol

    init(musicService: MusicServiceProtocol = MusicService()) {
        self.musicService = musicService
    }

    // MARK: - Taxonomy Access

    /// All available top-level genre categories.
    var categories: [GenreCategory] {
        GenreTaxonomy.categories
    }

    /// Get subcategories for a given category ID.
    func subcategories(for categoryID: String) -> [SubCategory] {
        GenreTaxonomy.category(withID: categoryID)?.subcategories ?? []
    }

    // MARK: - Chart Fetching

    /// Fetch chart albums for a specific genre category.
    func fetchChartAlbums(
        for category: GenreCategory,
        limit: Int = 25,
        offset: Int = 0
    ) async throws -> [CrateAlbum] {
        try await musicService.fetchChartAlbums(
            genreID: category.appleMusicID,
            limit: limit,
            offset: offset
        )
    }

    /// Fetch chart albums for a specific subcategory.
    func fetchChartAlbums(
        for subcategory: SubCategory,
        limit: Int = 25,
        offset: Int = 0
    ) async throws -> [CrateAlbum] {
        try await musicService.fetchChartAlbums(
            genreID: subcategory.appleMusicID,
            limit: limit,
            offset: offset
        )
    }

    /// Fetch chart albums using a raw Apple Music genre ID string.
    func fetchChartAlbums(
        genreID: String,
        limit: Int = 25,
        offset: Int = 0
    ) async throws -> [CrateAlbum] {
        try await musicService.fetchChartAlbums(
            genreID: genreID,
            limit: limit,
            offset: offset
        )
    }
}
