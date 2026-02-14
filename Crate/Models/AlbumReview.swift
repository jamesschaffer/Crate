import Foundation
import SwiftData

/// A cached AI-generated album review. Stored locally via SwiftData so
/// repeat visits to the same album load the review instantly.
@Model
final class AlbumReview {
    /// The Apple Music album ID (MusicItemID raw value).
    @Attribute(.unique) var albumID: String

    var contextSummary: String
    var contextBullets: [String]
    var rating: Double
    var recommendation: String
    var dateGenerated: Date

    init(
        albumID: String,
        contextSummary: String,
        contextBullets: [String],
        rating: Double,
        recommendation: String,
        dateGenerated: Date = .now
    ) {
        self.albumID = albumID
        self.contextSummary = contextSummary
        self.contextBullets = contextBullets
        self.rating = rating
        self.recommendation = recommendation
        self.dateGenerated = dateGenerated
    }
}
