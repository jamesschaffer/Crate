import Foundation
import MusicKit

// MARK: - Artwork Convenience

extension Artwork {
    /// Generate a URL for the artwork at a standard square size.
    /// Defaults to 300x300 which works well for grid items and detail views.
    func squareURL(size: Int = 300) -> URL? {
        url(width: size, height: size)
    }
}

// MARK: - Track Convenience

extension Track {
    /// Formatted duration string (e.g., "3:42").
    var formattedDuration: String? {
        guard let duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - MusicItemID Convenience

extension MusicItemID: @retroactive Comparable {
    public static func < (lhs: MusicItemID, rhs: MusicItemID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
