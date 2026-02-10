import Foundation
import SwiftData

/// A persisted disliked album. Stored locally via SwiftData so disliked
/// albums can be filtered from all feeds across sessions.
@Model
final class DislikedAlbum {
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
