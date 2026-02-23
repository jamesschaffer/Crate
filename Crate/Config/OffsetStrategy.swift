import Foundation

/// Pure utility for generating dial-scaled random offsets.
///
/// Charts have ~200 entries per genre. Randomizing the starting offset
/// means different albums each session. The dial controls how deep we explore.
struct OffsetStrategy: Sendable {

    /// Over-fetch multiplier — fetch 2x and randomly sample to target count.
    static let overFetchMultiplier: Double = 2.0

    /// Random chart offset scaled by dial position.
    static func randomChartOffset(for position: CrateDialPosition) -> Int {
        let maxOffset: Int
        switch position {
        case .myCrate:      maxOffset = 15
        case .curated:      maxOffset = 40
        case .mixedCrate:   maxOffset = 80
        case .deepDig:      maxOffset = 130
        case .mysteryCrate: maxOffset = 180
        }
        return Int.random(in: 0...maxOffset)
    }

    /// Random new-release offset scaled by dial position (capped at 80).
    static func randomNewReleaseOffset(for position: CrateDialPosition) -> Int {
        let maxOffset: Int
        switch position {
        case .myCrate:      maxOffset = 15
        case .curated:      maxOffset = 40
        case .mixedCrate:   maxOffset = 80
        case .deepDig:      maxOffset = 80
        case .mysteryCrate: maxOffset = 80
        }
        return Int.random(in: 0...maxOffset)
    }

    /// Random library offset scaled by dial position (half the chart range).
    static func randomLibraryOffset(for position: CrateDialPosition) -> Int {
        let maxOffset: Int
        switch position {
        case .myCrate:      maxOffset = 7
        case .curated:      maxOffset = 20
        case .mixedCrate:   maxOffset = 40
        case .deepDig:      maxOffset = 65
        case .mysteryCrate: maxOffset = 90
        }
        return Int.random(in: 0...maxOffset)
    }
}
