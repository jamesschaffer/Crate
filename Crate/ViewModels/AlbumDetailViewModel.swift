import Foundation
import MusicKit
import Observation

/// Manages state for the Album Detail screen: tracks, favorite toggle, metadata.
@Observable
final class AlbumDetailViewModel {

    // MARK: - Dependencies

    private let musicService: MusicServiceProtocol
    private let favoritesService: FavoritesService

    // MARK: - State

    /// The album being viewed.
    var album: CrateAlbum?

    /// Tracks belonging to this album.
    var tracks: MusicItemCollection<Track>?

    /// Whether this album is in the user's favorites.
    var isFavorite: Bool = false

    /// True while loading tracks.
    var isLoading: Bool = false

    /// Error message if track fetch fails.
    var errorMessage: String?

    // MARK: - Init

    init(musicService: MusicServiceProtocol = MusicService(),
         favoritesService: FavoritesService = FavoritesService()) {
        self.musicService = musicService
        self.favoritesService = favoritesService
    }

    // MARK: - Actions

    /// Load album details: tracks and favorite state.
    @MainActor
    func loadAlbum(_ album: CrateAlbum) async {
        self.album = album
        isLoading = true
        errorMessage = nil

        // Check favorite state
        isFavorite = favoritesService.isFavorite(albumID: album.id.rawValue)

        // Load tracks
        do {
            tracks = try await musicService.fetchAlbumTracks(albumID: album.id)
        } catch {
            errorMessage = "Could not load tracks: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Toggle whether this album is a favorite.
    @MainActor
    func toggleFavorite() {
        guard let album else { return }

        if isFavorite {
            favoritesService.removeFavorite(albumID: album.id.rawValue)
        } else {
            favoritesService.addFavorite(
                albumID: album.id.rawValue,
                title: album.title,
                artistName: album.artistName,
                artworkURL: album.artworkURL
            )
        }

        isFavorite.toggle()
    }
}
