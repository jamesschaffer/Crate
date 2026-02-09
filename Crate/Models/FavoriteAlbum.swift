import Foundation
import SwiftData

/// A persisted favorite album. Stored locally via SwiftData so the user's
/// favorites survive across launches without requiring a backend.
@Model
final class FavoriteAlbum {
    /// The Apple Music album ID (MusicItemID raw value).
    @Attribute(.unique) var albumID: String

    var title: String
    var artistName: String

    /// URL string for the album artwork — resolved from MusicKit's Artwork at save time.
    var artworkURL: String?

    var dateAdded: Date

    init(
        albumID: String,
        title: String,
        artistName: String,
        artworkURL: String? = nil,
        dateAdded: Date = .now
    ) {
        self.albumID = albumID
        self.title = title
        self.artistName = artistName
        self.artworkURL = artworkURL
        self.dateAdded = dateAdded
    }
}
