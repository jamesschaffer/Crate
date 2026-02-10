import Foundation

/// The six signal sources that feed per-genre album feeds.
enum GenreFeedSignal: CaseIterable, Hashable, Sendable {
    case personalHistory
    case recommendations
    case trending
    case newReleases
    case subcategoryRotation
    case seedExpansion
}

/// Weight tables for genre feeds at each CrateDial position.
struct GenreFeedWeights: Sendable {

    let values: [GenreFeedSignal: Double]

    /// Look up the genre feed weight table for a given dial position.
    static func weights(for position: CrateDialPosition) -> GenreFeedWeights {
        switch position {
        case .myCrate:
            GenreFeedWeights(values: [
                .personalHistory: 0.30,
                .recommendations: 0.25,
                .trending: 0.10,
                .newReleases: 0.05,
                .subcategoryRotation: 0.10,
                .seedExpansion: 0.20,
            ])
        case .curated:
            GenreFeedWeights(values: [
                .personalHistory: 0.20,
                .recommendations: 0.20,
                .trending: 0.15,
                .newReleases: 0.10,
                .subcategoryRotation: 0.15,
                .seedExpansion: 0.20,
            ])
        case .mixedCrate:
            GenreFeedWeights(values: [
                .personalHistory: 0.10,
                .recommendations: 0.15,
                .trending: 0.20,
                .newReleases: 0.20,
                .subcategoryRotation: 0.20,
                .seedExpansion: 0.15,
            ])
        case .deepDig:
            GenreFeedWeights(values: [
                .personalHistory: 0.05,
                .recommendations: 0.10,
                .trending: 0.15,
                .newReleases: 0.25,
                .subcategoryRotation: 0.35,
                .seedExpansion: 0.10,
            ])
        case .mysteryCrate:
            GenreFeedWeights(values: [
                .personalHistory: 0.00,
                .recommendations: 0.05,
                .trending: 0.10,
                .newReleases: 0.20,
                .subcategoryRotation: 0.55,
                .seedExpansion: 0.10,
            ])
        }
    }

    /// Convert fractional weights to integer album counts that sum to `total`.
    /// Uses largest-remainder method so rounding errors don't lose albums.
    func albumCounts(total: Int) -> [GenreFeedSignal: Int] {
        let raw = values.mapValues { $0 * Double(total) }
        var floored = raw.mapValues { Int($0) }
        let assigned = floored.values.reduce(0, +)
        var remainder = total - assigned

        let sorted = raw.sorted { ($0.value - Double(Int($0.value))) > ($1.value - Double(Int($1.value))) }
        for entry in sorted where remainder > 0 {
            floored[entry.key, default: 0] += 1
            remainder -= 1
        }

        return floored
    }
}
