import Foundation
import MusicKit
import Observation
import SwiftData

/// Manages state for the Album Detail screen: tracks, favorite toggle, dislike toggle, metadata.
@MainActor
@Observable
final class AlbumDetailViewModel {

    // MARK: - Dependencies

    private let musicService: MusicServiceProtocol
    private let favoritesService: FavoritesService
    private let dislikeService: DislikeService

    // MARK: - State

    /// The album being viewed.
    var album: CrateAlbum?

    /// Tracks belonging to this album.
    var tracks: MusicItemCollection<Track>?

    /// Whether this album is in the user's favorites.
    var isFavorite: Bool = false

    /// Whether this album is disliked.
    var isDisliked: Bool = false

    /// True while loading tracks.
    var isLoading: Bool = false

    /// Error message if track fetch fails.
    var errorMessage: String?

    // MARK: - Init

    init(musicService: MusicServiceProtocol = MusicService(),
         favoritesService: FavoritesService = FavoritesService(),
         dislikeService: DislikeService = DislikeService()) {
        self.musicService = musicService
        self.favoritesService = favoritesService
        self.dislikeService = dislikeService
    }

    // MARK: - Configuration

    /// Inject the SwiftData model context into both services.
    /// Call this from the view layer before any CRUD operations.
    func configure(modelContext: ModelContext) {
        favoritesService.modelContext = modelContext
        dislikeService.modelContext = modelContext
    }

    // MARK: - Actions

    /// Load album details: tracks, favorite state, and dislike state.
    func loadAlbum(_ album: CrateAlbum) async {
        self.album = album
        isLoading = true
        errorMessage = nil

        // Check favorite and dislike state
        isFavorite = favoritesService.isFavorite(albumID: album.id.rawValue)
        isDisliked = dislikeService.isDisliked(albumID: album.id.rawValue)

        // Load tracks
        do {
            tracks = try await musicService.fetchAlbumTracks(albumID: album.id)
        } catch {
            errorMessage = "Could not load tracks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Toggle whether this album is a favorite.
    /// When favoriting: also adds to Apple Music library and rates as love.
    /// When unfavoriting: only removes from local SwiftData (non-destructive).
    func toggleFavorite() {
        guard let album else { return }

        if isFavorite {
            favoritesService.removeFavorite(albumID: album.id.rawValue)
            isFavorite = false
        } else {
            // Mutual exclusion: remove dislike if active
            if isDisliked {
                dislikeService.removeDislike(albumID: album.id.rawValue)
                isDisliked = false
            }

            favoritesService.addFavorite(
                albumID: album.id.rawValue,
                title: album.title,
                artistName: album.artistName,
                artworkURL: album.artworkURL
            )
            isFavorite = true

            // Write back to Apple Music concurrently (fire-and-forget).
            // Running in parallel avoids user-token expiry between sequential calls.
            Task {
                async let lib: () = musicService.addToLibrary(albumID: album.id)
                async let rate: () = musicService.rateAlbum(id: album.id, rating: .love)
                async let fav: () = musicService.favoriteAlbum(id: album.id)

                do { try await lib } catch { print("[Crate] addToLibrary failed: \(error)") }
                do { try await rate } catch { print("[Crate] rateAlbum(.love) failed: \(error)") }
                do { try await fav } catch { print("[Crate] favoriteAlbum failed: \(error)") }
            }
        }
    }

    /// Toggle whether this album is disliked.
    /// When disliking: rates as dislike in Apple Music.
    /// When un-disliking: only removes from local SwiftData (non-destructive).
    func toggleDislike() {
        guard let album else { return }

        if isDisliked {
            dislikeService.removeDislike(albumID: album.id.rawValue)
            isDisliked = false
        } else {
            // Mutual exclusion: remove favorite if active
            if isFavorite {
                favoritesService.removeFavorite(albumID: album.id.rawValue)
                isFavorite = false
            }

            dislikeService.addDislike(
                albumID: album.id.rawValue,
                title: album.title,
                artistName: album.artistName,
                artworkURL: album.artworkURL
            )
            isDisliked = true

            // Write back to Apple Music (fire-and-forget)
            Task {
                do {
                    try await musicService.rateAlbum(id: album.id, rating: .dislike)
                } catch { print("[Crate] rateAlbum(.dislike) failed: \(error)") }
            }
        }
    }
}
