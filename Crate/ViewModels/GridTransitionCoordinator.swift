import SwiftUI
import Observation

/// Orchestrates scatter/fade animations when the album grid transitions
/// between wall ↔ genre or genre ↔ genre.
///
/// During `.idle` the coordinator is a passthrough — no animation overhead.
/// It only manages `displayAlbums` and `itemStates` during transitions.
@Observable
@MainActor
final class GridTransitionCoordinator {

    // MARK: - Phase

    enum Phase {
        /// Normal operation. Grid reads albums directly from view models.
        case idle
        /// Old albums animating out (scale + fade).
        case exiting
        /// Grid empty, scroll resetting. Spinner if API hasn't returned.
        case waiting
        /// New albums animating in (hidden → visible).
        case entering
    }

    // MARK: - Item Animation State

    struct ItemState {
        var scale: CGFloat
        var opacity: Double
    }

    // MARK: - Published State

    /// Current animation phase.
    private(set) var phase: Phase = .idle

    /// Albums to display during a transition. Empty during `.idle`.
    private(set) var displayAlbums: [CrateAlbum] = []

    /// Per-item animation states keyed by index. Empty during `.idle`.
    private(set) var itemStates: [Int: ItemState] = [:]

    /// Toggles to trigger scroll-to-top in AlbumGridView.
    var scrollToTopTrigger: Bool = false

    /// Whether a waiting spinner should show (exit done, data not yet back).
    private(set) var showWaitingSpinner: Bool = false

    /// Whether the genre bar should animate its pills during this transition.
    private(set) var animateGenreBar: Bool = false

    /// True during any non-idle phase. Use to disable genre bar interaction.
    var isTransitioning: Bool {
        phase != .idle
    }

    // MARK: - Private

    /// Tracks the current transition so re-entrant taps can cancel it.
    private var transitionTask: Task<Void, Never>?

    // MARK: - Main Entry Point

    /// Run a coordinated exit → fetch → enter transition.
    ///
    /// - Parameters:
    ///   - oldAlbums: Snapshot of albums currently displayed (for exit animation).
    ///   - fetch: Async closure that triggers the VM action and returns the new albums.
    func transition(from oldAlbums: [CrateAlbum], animateGenreBar: Bool = false, fetch: @escaping () async -> [CrateAlbum]) {
        // Cancel any in-progress transition.
        cancel()

        transitionTask = Task { @MainActor [weak self] in
            guard let self else { return }

            self.animateGenreBar = animateGenreBar

            // --- Exit Phase ---
            self.displayAlbums = oldAlbums
            self.phase = .exiting

            // Pre-populate all items as visible so they start at full scale/opacity.
            self.itemStates = [:]
            for i in 0..<oldAlbums.count {
                self.itemStates[i] = ItemState(scale: 1.0, opacity: 1.0)
            }

            await self.runExitAnimation(itemCount: oldAlbums.count)

            guard !Task.isCancelled else { return self.resetToIdle() }

            // --- Waiting Phase ---
            self.phase = .waiting
            self.displayAlbums = []
            self.itemStates = [:]
            self.showWaitingSpinner = true

            // Snap scroll to top.
            self.scrollToTopTrigger.toggle()

            // Kick off the actual data fetch.
            let newAlbums = await fetch()

            guard !Task.isCancelled else { return self.resetToIdle() }

            self.showWaitingSpinner = false

            // --- Enter Phase ---
            guard !newAlbums.isEmpty else {
                // No results — go idle so the empty-state overlay can show.
                self.resetToIdle()
                return
            }

            self.displayAlbums = newAlbums
            self.phase = .entering

            // Pre-populate items as hidden.
            self.itemStates = [:]
            for i in 0..<newAlbums.count {
                self.itemStates[i] = ItemState(
                    scale: GridTransition.hiddenScale,
                    opacity: GridTransition.hiddenOpacity
                )
            }

            // Brief pause so SwiftUI can lay out the hidden items.
            try? await Task.sleep(for: .seconds(GridTransition.phasePause))
            guard !Task.isCancelled else { return self.resetToIdle() }

            await self.runEnterAnimation(itemCount: newAlbums.count)

            guard !Task.isCancelled else { return self.resetToIdle() }

            // --- Back to Idle ---
            self.resetToIdle()
        }
    }

    /// Cancel the current transition and snap to idle.
    func cancel() {
        transitionTask?.cancel()
        transitionTask = nil
        if phase != .idle {
            resetToIdle()
        }
    }

    // MARK: - Exit Animation

    private func runExitAnimation(itemCount: Int) async {
        let scatterCount = min(itemCount, GridTransition.scatterItemCount)
        let schedule = Self.staggerSchedule(itemCount: scatterCount, exiting: true)

        // Fire off staggered scatter animations.
        for entry in schedule {
            withAnimation(GridTransition.exitCurve) {
                self.itemStates[entry.index] = ItemState(
                    scale: GridTransition.hiddenScale,
                    opacity: GridTransition.hiddenOpacity
                )
            }

            // Sleep for the delay until the next item fires.
            if entry.delay > 0 {
                try? await Task.sleep(for: .seconds(entry.delay))
                if Task.isCancelled { return }
            }
        }

        // Bulk fade for items beyond the scatter set.
        if itemCount > GridTransition.scatterItemCount {
            withAnimation(GridTransition.bulkCurve) {
                for i in GridTransition.scatterItemCount..<itemCount {
                    self.itemStates[i] = ItemState(
                        scale: GridTransition.hiddenScale,
                        opacity: GridTransition.hiddenOpacity
                    )
                }
            }
        }

        // Wait for the last animation to finish.
        let totalWait = GridTransition.perItemDuration + 0.05
        try? await Task.sleep(for: .seconds(totalWait))
    }

    // MARK: - Enter Animation

    private func runEnterAnimation(itemCount: Int) async {
        let scatterCount = min(itemCount, GridTransition.scatterItemCount)
        let schedule = Self.staggerSchedule(itemCount: scatterCount, exiting: false)

        // Fire off staggered scatter animations.
        for entry in schedule {
            withAnimation(GridTransition.enterCurve) {
                self.itemStates[entry.index] = ItemState(scale: 1.0, opacity: 1.0)
            }

            if entry.delay > 0 {
                try? await Task.sleep(for: .seconds(entry.delay))
                if Task.isCancelled { return }
            }
        }

        // Bulk fade-in for items beyond the scatter set.
        if itemCount > GridTransition.scatterItemCount {
            withAnimation(GridTransition.bulkCurve) {
                for i in GridTransition.scatterItemCount..<itemCount {
                    self.itemStates[i] = ItemState(scale: 1.0, opacity: 1.0)
                }
            }
        }

        // Wait for animations to settle.
        let totalWait = GridTransition.perItemDuration + 0.05
        try? await Task.sleep(for: .seconds(totalWait))
    }

    // MARK: - Stagger Schedule

    private struct StaggerEntry {
        let index: Int
        /// Delay *from the previous entry* (not absolute).
        let delay: Double
    }

    /// Build an interleaved stagger schedule for the scatter items.
    ///
    /// Group A = indices 0..<groupSize, Group B = indices groupSize..<scatterCount.
    /// Interleave: A₀, B₀, A₁, B₁, … with stagger spread across the window.
    /// A small random jitter prevents mechanical uniformity.
    private static func staggerSchedule(itemCount: Int, exiting: Bool) -> [StaggerEntry] {
        guard itemCount > 0 else { return [] }

        let groupA = Array(0..<min(itemCount, GridTransition.groupSize))
        let groupB = Array(GridTransition.groupSize..<itemCount)

        // Interleave the two groups.
        var interleaved: [Int] = []
        let maxLen = max(groupA.count, groupB.count)
        for i in 0..<maxLen {
            if i < groupA.count { interleaved.append(groupA[i]) }
            if i < groupB.count { interleaved.append(groupB[i]) }
        }

        // Calculate absolute times with jitter.
        let step = interleaved.count > 1
            ? GridTransition.staggerWindow / Double(interleaved.count - 1)
            : 0

        var entries: [StaggerEntry] = []
        var previousTime: Double = 0

        for (slot, index) in interleaved.enumerated() {
            let jitter = Double.random(in: 0...GridTransition.maxJitter)
            let absoluteTime = Double(slot) * step + jitter
            let relativeDelay = max(0, absoluteTime - previousTime)
            entries.append(StaggerEntry(index: index, delay: relativeDelay))
            previousTime = absoluteTime
        }

        return entries
    }

    // MARK: - Helpers

    private func resetToIdle() {
        phase = .idle
        displayAlbums = []
        itemStates = [:]
        showWaitingSpinner = false
        animateGenreBar = false
    }
}
