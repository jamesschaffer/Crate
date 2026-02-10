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
        guard let ctx = modelContext else { return }

        let favorite = FavoriteAlbum(
            albumID: albumID,
            title: title,
            artistName: artistName,
            artworkURL: artworkURL
        )

        ctx.insert(favorite)
        try? ctx.save()
    }

    /// Remove an album from favorites by its Apple Music ID.
    @MainActor
    func removeFavorite(albumID: String) {
        guard let ctx = modelContext else { return }

        let predicate = #Predicate<FavoriteAlbum> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        guard let favorites = try? ctx.fetch(descriptor),
              let favorite = favorites.first else {
            return
        }

        ctx.delete(favorite)
        try? ctx.save()
    }

    /// Check if an album is in favorites.
    @MainActor
    func isFavorite(albumID: String) -> Bool {
        guard let ctx = modelContext else { return false }

        let predicate = #Predicate<FavoriteAlbum> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        let count = (try? ctx.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    /// Fetch all favorite albums, newest first.
    @MainActor
    func fetchAll() -> [FavoriteAlbum] {
        guard let ctx = modelContext else { return [] }

        var descriptor = FetchDescriptor<FavoriteAlbum>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        descriptor.fetchLimit = 500

        return (try? ctx.fetch(descriptor)) ?? []
    }
}
