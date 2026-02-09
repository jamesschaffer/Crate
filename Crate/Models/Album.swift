import Foundation
import MusicKit

/// A lightweight wrapper around album data, holding only the fields
/// Crate needs for display and identification.
struct CrateAlbum: Identifiable, Hashable, Sendable {
    let id: MusicItemID
    let title: String
    let artistName: String
    let artwork: Artwork?
    let artworkURL: String?
    let releaseDate: Date?
    let genreNames: [String]

    /// Initialize from a MusicKit Album.
    init(from album: Album) {
        self.id = album.id
        self.title = album.title
        self.artistName = album.artistName
        self.artwork = album.artwork
        self.artworkURL = nil
        self.releaseDate = album.releaseDate
        self.genreNames = album.genreNames
    }

    /// Initialize from chart response data (no MusicKit Album object available).
    init(id: MusicItemID, title: String, artistName: String, artworkURL: String?, releaseDate: Date?, genreNames: [String]) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artwork = nil
        self.artworkURL = artworkURL
        self.releaseDate = releaseDate
        self.genreNames = genreNames
    }

    // Manual Hashable conformance — Artwork is not Hashable,
    // so we hash only by id which uniquely identifies an album.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CrateAlbum, rhs: CrateAlbum) -> Bool {
        lhs.id == rhs.id
    }
}
