import Foundation
import MusicKit
import Observation

/// Manages state for the artist catalog screen: fetches all albums by an artist.
@MainActor
@Observable
final class ArtistCatalogViewModel {

    private let musicService: MusicServiceProtocol

    var albums: [CrateAlbum] = []
    var isLoading: Bool = false
    var errorMessage: String?

    init(musicService: MusicServiceProtocol = MusicService()) {
        self.musicService = musicService
    }

    /// Look up the artist from the album, then fetch their full catalog.
    func load(albumID: MusicItemID) async {
        isLoading = true
        errorMessage = nil

        do {
            guard let artistID = try await musicService.fetchArtistID(forAlbumID: albumID) else {
                errorMessage = "Could not find artist for this album."
                isLoading = false
                return
            }

            let fetched = try await musicService.fetchArtistAlbums(artistID: artistID)

            // Sort oldest-first; albums without a release date sort to the end.
            albums = fetched.sorted { a, b in
                switch (a.releaseDate, b.releaseDate) {
                case let (dateA?, dateB?):
                    return dateA < dateB
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return false
                }
            }
        } catch {
            print("[Crate] Failed to load artist catalog: \(error)")
            errorMessage = "Could not load artist albums."
        }

        isLoading = false
    }
}
