import SwiftUI

/// Tuning constants for the genre-switch scatter/fade animation.
enum GridTransition {

    // MARK: - Item Counts

    /// Number of items that get the full scatter (scale + fade) effect.
    static let scatterItemCount = 16

    /// Items per interleave group (first half / second half of scatter items).
    static let groupSize = 8

    // MARK: - Timing

    /// Duration of each individual item's scale + fade animation.
    static let perItemDuration: Double = 0.25

    /// Total time window over which scatter items are staggered.
    static let staggerWindow: Double = 0.4

    /// Duration for bulk fade on items beyond scatterItemCount.
    static let bulkFadeDuration: Double = 0.15

    /// Maximum random jitter added to each item's stagger delay.
    static let maxJitter: Double = 0.04

    /// Brief pause between exit finishing and enter starting.
    static let phasePause: Double = 0.04

    // MARK: - Scale / Opacity

    /// Scale target for hidden items (near-zero avoids layout collapse).
    static let hiddenScale: CGFloat = 0.01

    /// Opacity target for hidden items.
    static let hiddenOpacity: Double = 0

    // MARK: - Easing

    /// Easing curve for exit animations.
    static let exitCurve: Animation = .easeIn(duration: perItemDuration)

    /// Easing curve for enter animations.
    static let enterCurve: Animation = .easeOut(duration: perItemDuration)

    /// Easing curve for bulk fade.
    static let bulkCurve: Animation = .easeIn(duration: bulkFadeDuration)
}
