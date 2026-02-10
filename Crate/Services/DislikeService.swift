import Foundation
import SwiftData

/// CRUD operations for the user's disliked albums, backed by SwiftData.
///
/// Mirrors FavoritesService — all methods that touch the ModelContext
/// must be called from @MainActor.
final class DislikeService {

    // MARK: - Model Context

    private var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    /// Mark an album as disliked.
    @MainActor
    func addDislike(
        albumID: String,
        title: String,
        artistName: String,
        artworkURL: String?
    ) {
        guard let ctx = modelContext else { return }

        let disliked = DislikedAlbum(
            albumID: albumID,
            title: title,
            artistName: artistName,
            artworkURL: artworkURL
        )

        ctx.insert(disliked)
        try? ctx.save()
    }

    /// Remove an album from the disliked list.
    @MainActor
    func removeDislike(albumID: String) {
        guard let ctx = modelContext else { return }

        let predicate = #Predicate<DislikedAlbum> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        guard let disliked = try? ctx.fetch(descriptor),
              let item = disliked.first else {
            return
        }

        ctx.delete(item)
        try? ctx.save()
    }

    /// Check if an album is disliked.
    @MainActor
    func isDisliked(albumID: String) -> Bool {
        guard let ctx = modelContext else { return false }

        let predicate = #Predicate<DislikedAlbum> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        let count = (try? ctx.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    /// Fetch all disliked album IDs for efficient feed filtering.
    @MainActor
    func fetchAllDislikedIDs() -> Set<String> {
        guard let ctx = modelContext else { return [] }

        let descriptor = FetchDescriptor<DislikedAlbum>()
        let items = (try? ctx.fetch(descriptor)) ?? []
        return Set(items.map(\.albumID))
    }
}
