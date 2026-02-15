import Foundation
import SwiftData

/// CRUD operations for the user's favorite albums, backed by SwiftData.
///
/// All methods that touch the ModelContext must be called from @MainActor.
/// The service itself is not @MainActor so it can be stored as a property
/// in @Observable view models without isolation conflicts.
final class FavoritesService {

    // MARK: - Model Context

    /// The model context — injected at init or set later via the view layer.
    var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    /// Add an album to favorites.
    @MainActor
    func addFavorite(
        albumID: String,
        title: String,
        artistName: String,
        artworkURL: String?
    ) {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] FavoritesService.addFavorite called before configure(modelContext:)")
            return
        }

        let favorite = FavoriteAlbum(
            albumID: albumID,
            title: title,
            artistName: artistName,
            artworkURL: artworkURL
        )

        ctx.insert(favorite)
        do {
            try ctx.save()
        } catch {
            #if DEBUG
            print("[Crate] SwiftData save failed: \(error)")
            #endif
        }
    }

    /// Remove an album from favorites by its Apple Music ID.
    @MainActor
    func removeFavorite(albumID: String) {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] FavoritesService.removeFavorite called before configure(modelContext:)")
            return
        }

        let predicate = #Predicate<FavoriteAlbum> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let favorites = try ctx.fetch(descriptor)
            guard let favorite = favorites.first else { return }
            ctx.delete(favorite)
            try ctx.save()
        } catch {
            #if DEBUG
            print("[Crate] SwiftData delete/save failed: \(error)")
            #endif
        }
    }

    /// Check if an album is in favorites.
    @MainActor
    func isFavorite(albumID: String) -> Bool {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] FavoritesService.isFavorite called before configure(modelContext:)")
            return false
        }

        let predicate = #Predicate<FavoriteAlbum> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let count = try ctx.fetchCount(descriptor)
            return count > 0
        } catch {
            #if DEBUG
            print("[Crate] FavoritesService.isFavorite fetch failed: \(error)")
            #endif
            return false
        }
    }

    /// Fetch all favorite albums, newest first.
    @MainActor
    func fetchAll() -> [FavoriteAlbum] {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] FavoritesService.fetchAll called before configure(modelContext:)")
            return []
        }

        var descriptor = FetchDescriptor<FavoriteAlbum>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        descriptor.fetchLimit = 500

        do {
            return try ctx.fetch(descriptor)
        } catch {
            #if DEBUG
            print("[Crate] FavoritesService.fetchAll failed: \(error)")
            #endif
            return []
        }
    }
}
