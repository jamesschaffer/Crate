import Foundation
import MusicKit
import Observation

/// Drives the Crate Wall — the algorithm-driven landing experience.
///
/// Owned as `@State` on BrowseView so it persists within a session
/// (survives navigation push/pop) but resets on cold launch.
@Observable
final class CrateWallViewModel {

    // MARK: - State

    /// Albums currently displayed in the wall grid.
    var albums: [CrateAlbum] = []

    /// True while generating the initial wall.
    var isLoading: Bool = false

    /// True while fetching more albums for infinite scroll.
    var isLoadingMore: Bool = false

    /// Set when wall generation fails.
    var errorMessage: String?

    /// Whether the wall has been generated this session.
    private(set) var hasGenerated: Bool = false

    // MARK: - Dedup

    /// IDs of albums already in the wall, used to exclude from fetchMore.
    private var existingIDs: Set<MusicItemID> = []

    // MARK: - Dependencies

    private let wallService: CrateWallService

    init(wallService: CrateWallService = CrateWallService()) {
        self.wallService = wallService
    }

    // MARK: - Actions

    /// Generate the wall if it hasn't been generated yet this session.
    func generateWallIfNeeded() async {
        guard !hasGenerated else { return }
        isLoading = true
        errorMessage = nil

        let wall = await wallService.generateWall()

        if wall.isEmpty {
            errorMessage = "Couldn't load the Crate Wall. Check your connection and try again."
        } else {
            albums = wall
            existingIDs = Set(wall.map(\.id))
        }

        hasGenerated = true
        isLoading = false
    }

    /// Fetch more albums for infinite scroll. Call when the user nears the bottom.
    func fetchMoreIfNeeded() async {
        guard !isLoadingMore, hasGenerated else { return }
        isLoadingMore = true

        let more = await wallService.fetchMore(excluding: existingIDs)
        albums.append(contentsOf: more)
        existingIDs.formUnion(more.map(\.id))

        isLoadingMore = false
    }

    /// Force-regenerate the wall (e.g. after a retry).
    func regenerate() async {
        hasGenerated = false
        albums = []
        existingIDs = []
        errorMessage = nil
        await generateWallIfNeeded()
    }
}
