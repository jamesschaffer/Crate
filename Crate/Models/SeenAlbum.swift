import Foundation
import SwiftData

/// A persisted record of an album shown in the feed. Stored locally via SwiftData
/// so albums shown in recent sessions can be suppressed to improve variability.
@Model
final class SeenAlbum {
    /// The Apple Music album ID (MusicItemID raw value).
    @Attribute(.unique) var albumID: String

    /// When this album was last shown.
    var dateSeen: Date

    init(albumID: String, dateSeen: Date = .now) {
        self.albumID = albumID
        self.dateSeen = dateSeen
    }
}
