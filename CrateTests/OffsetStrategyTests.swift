import Foundation
import Testing
@testable import Crate_iOS

/// Tests for OffsetStrategy — verifies offset ranges are correct for each dial position.
struct OffsetStrategyTests {

    // MARK: - Chart Offsets

    @Test("Chart offset for My Crate is within 0...15")
    func chartOffsetMyCrate() {
        for _ in 0..<50 {
            let offset = OffsetStrategy.randomChartOffset(for: .myCrate)
            #expect(offset >= 0 && offset <= 15)
        }
    }

    @Test("Chart offset for Curated is within 0...40")
    func chartOffsetCurated() {
        for _ in 0..<50 {
            let offset = OffsetStrategy.randomChartOffset(for: .curated)
            #expect(offset >= 0 && offset <= 40)
        }
    }

    @Test("Chart offset for Mixed Crate is within 0...80")
    func chartOffsetMixedCrate() {
        for _ in 0..<50 {
            let offset = OffsetStrategy.randomChartOffset(for: .mixedCrate)
            #expect(offset >= 0 && offset <= 80)
        }
    }

    @Test("Chart offset for Deep Dig is within 0...130")
    func chartOffsetDeepDig() {
        for _ in 0..<50 {
            let offset = OffsetStrategy.randomChartOffset(for: .deepDig)
            #expect(offset >= 0 && offset <= 130)
        }
    }

    @Test("Chart offset for Mystery Crate is within 0...180")
    func chartOffsetMysteryCrate() {
        for _ in 0..<50 {
            let offset = OffsetStrategy.randomChartOffset(for: .mysteryCrate)
            #expect(offset >= 0 && offset <= 180)
        }
    }

    // MARK: - New Release Offsets

    @Test("New release offset caps at 80 for Deep Dig and Mystery Crate")
    func newReleaseOffsetCap() {
        for _ in 0..<50 {
            let deepDig = OffsetStrategy.randomNewReleaseOffset(for: .deepDig)
            #expect(deepDig >= 0 && deepDig <= 80)

            let mystery = OffsetStrategy.randomNewReleaseOffset(for: .mysteryCrate)
            #expect(mystery >= 0 && mystery <= 80)
        }
    }

    @Test("New release offset for My Crate is within 0...15")
    func newReleaseOffsetMyCrate() {
        for _ in 0..<50 {
            let offset = OffsetStrategy.randomNewReleaseOffset(for: .myCrate)
            #expect(offset >= 0 && offset <= 15)
        }
    }

    // MARK: - Library Offsets

    @Test("Library offset for My Crate is within 0...7")
    func libraryOffsetMyCrate() {
        for _ in 0..<50 {
            let offset = OffsetStrategy.randomLibraryOffset(for: .myCrate)
            #expect(offset >= 0 && offset <= 7)
        }
    }

    @Test("Library offset for Mystery Crate is within 0...90")
    func libraryOffsetMysteryCrate() {
        for _ in 0..<50 {
            let offset = OffsetStrategy.randomLibraryOffset(for: .mysteryCrate)
            #expect(offset >= 0 && offset <= 90)
        }
    }

    // MARK: - Over-Fetch Multiplier

    @Test("Over-fetch multiplier is 2.0")
    func overFetchMultiplier() {
        #expect(OffsetStrategy.overFetchMultiplier == 2.0)
    }

    // MARK: - Monotonically Increasing Ranges

    @Test("Chart offset max increases with dial position")
    func chartOffsetIncreases() {
        // Run many samples and check that higher positions can produce higher offsets.
        var maxByPosition: [CrateDialPosition: Int] = [:]
        for position in CrateDialPosition.allCases {
            var maxVal = 0
            for _ in 0..<200 {
                maxVal = max(maxVal, OffsetStrategy.randomChartOffset(for: position))
            }
            maxByPosition[position] = maxVal
        }

        // Each position's observed max should be >= the previous position's observed max.
        let ordered = CrateDialPosition.allCases.sorted { $0.rawValue < $1.rawValue }
        for i in 1..<ordered.count {
            let prev = maxByPosition[ordered[i - 1]]!
            let curr = maxByPosition[ordered[i]]!
            #expect(curr >= prev, "\(ordered[i].label) max (\(curr)) should be >= \(ordered[i-1].label) max (\(prev))")
        }
    }
}
