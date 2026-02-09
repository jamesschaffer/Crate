import Foundation

/// Discrete positions on the Crate Dial slider.
/// Lower values lean toward personal listening data; higher values
/// explore further from the user's comfort zone.
enum CrateDialPosition: Int, CaseIterable, Sendable {
    case myCrate = 1
    case curated = 2
    case mixedCrate = 3
    case deepDig = 4
    case mysteryCrate = 5

    var label: String {
        switch self {
        case .myCrate: "My Crate"
        case .curated: "Curated"
        case .mixedCrate: "Mixed Crate"
        case .deepDig: "Deep Dig"
        case .mysteryCrate: "Mystery Crate"
        }
    }

    var description: String {
        switch self {
        case .myCrate:
            "Albums based almost entirely on what you already listen to."
        case .curated:
            "Mostly familiar territory with a few curated picks mixed in."
        case .mixedCrate:
            "A balanced mix of your taste, recommendations, and popular albums."
        case .deepDig:
            "Leans toward discovery — new releases, deep cuts, and surprises."
        case .mysteryCrate:
            "Almost entirely random. You never know what you're going to get."
        }
    }
}

/// The five signal sources that feed the Crate Wall.
enum WallSignal: CaseIterable, Sendable {
    case listeningHistory
    case recommendations
    case popularCharts
    case newReleases
    case wildCard
}

/// Weight table for each dial position.
/// Values are fractional (sum to 1.0) and represent the proportion of
/// wall slots each signal should fill.
struct CrateDialWeights: Sendable {

    let values: [WallSignal: Double]

    /// Look up the weight table for a given dial position.
    static func weights(for position: CrateDialPosition) -> CrateDialWeights {
        switch position {
        case .myCrate:
            CrateDialWeights(values: [
                .listeningHistory: 0.45,
                .recommendations: 0.30,
                .popularCharts: 0.15,
                .newReleases: 0.05,
                .wildCard: 0.05,
            ])
        case .curated:
            CrateDialWeights(values: [
                .listeningHistory: 0.30,
                .recommendations: 0.30,
                .popularCharts: 0.20,
                .newReleases: 0.10,
                .wildCard: 0.10,
            ])
        case .mixedCrate:
            CrateDialWeights(values: [
                .listeningHistory: 0.20,
                .recommendations: 0.20,
                .popularCharts: 0.25,
                .newReleases: 0.20,
                .wildCard: 0.15,
            ])
        case .deepDig:
            CrateDialWeights(values: [
                .listeningHistory: 0.10,
                .recommendations: 0.15,
                .popularCharts: 0.20,
                .newReleases: 0.30,
                .wildCard: 0.25,
            ])
        case .mysteryCrate:
            CrateDialWeights(values: [
                .listeningHistory: 0.05,
                .recommendations: 0.05,
                .popularCharts: 0.15,
                .newReleases: 0.25,
                .wildCard: 0.50,
            ])
        }
    }

    /// Convert fractional weights to integer album counts that sum to `total`.
    /// Uses largest-remainder method so rounding errors don't lose albums.
    func albumCounts(total: Int) -> [WallSignal: Int] {
        let raw = values.mapValues { $0 * Double(total) }
        var floored = raw.mapValues { Int($0) }
        let assigned = floored.values.reduce(0, +)
        var remainder = total - assigned

        // Award leftover slots to signals with the largest fractional parts.
        let sorted = raw.sorted { ($0.value - Double(Int($0.value))) > ($1.value - Double(Int($1.value))) }
        for entry in sorted where remainder > 0 {
            floored[entry.key, default: 0] += 1
            remainder -= 1
        }

        return floored
    }
}
