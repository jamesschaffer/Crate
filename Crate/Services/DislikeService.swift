import Foundation
import SwiftData

/// CRUD operations for the user's disliked albums, backed by SwiftData.
///
/// Mirrors FavoritesService — all methods that touch the ModelContext
/// must be called from @MainActor.
final class DislikeService {

    // MARK: - Model Context

    /// The model context — injected at init or set later via the view layer.
    var modelContext: ModelContext?

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
        guard let ctx = modelContext else {
            assertionFailure("[Crate] DislikeService.addDislike called before configure(modelContext:)")
            return
        }

        let disliked = DislikedAlbum(
            albumID: albumID,
            title: title,
            artistName: artistName,
            artworkURL: artworkURL
        )

        ctx.insert(disliked)
        do {
            try ctx.save()
        } catch {
            #if DEBUG
            print("[Crate] SwiftData save failed: \(error)")
            #endif
        }
    }

    /// Remove an album from the disliked list.
    @MainActor
    func removeDislike(albumID: String) {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] DislikeService.removeDislike called before configure(modelContext:)")
            return
        }

        let predicate = #Predicate<DislikedAlbum> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let disliked = try ctx.fetch(descriptor)
            guard let item = disliked.first else { return }
            ctx.delete(item)
            try ctx.save()
        } catch {
            #if DEBUG
            print("[Crate] SwiftData delete/save failed: \(error)")
            #endif
        }
    }

    /// Check if an album is disliked.
    @MainActor
    func isDisliked(albumID: String) -> Bool {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] DislikeService.isDisliked called before configure(modelContext:)")
            return false
        }

        let predicate = #Predicate<DislikedAlbum> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let count = try ctx.fetchCount(descriptor)
            return count > 0
        } catch {
            #if DEBUG
            print("[Crate] DislikeService.isDisliked fetch failed: \(error)")
            #endif
            return false
        }
    }

    /// Fetch all disliked album IDs for efficient feed filtering.
    @MainActor
    func fetchAllDislikedIDs() -> Set<String> {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] DislikeService.fetchAllDislikedIDs called before configure(modelContext:)")
            return []
        }

        let descriptor = FetchDescriptor<DislikedAlbum>()
        do {
            let items = try ctx.fetch(descriptor)
            return Set(items.map(\.albumID))
        } catch {
            #if DEBUG
            print("[Crate] DislikeService.fetchAllDislikedIDs failed: \(error)")
            #endif
            return []
        }
    }
}
