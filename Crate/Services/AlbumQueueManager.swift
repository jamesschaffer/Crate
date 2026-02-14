import Foundation
import MusicKit

/// A single entry in the diagnostics track queue.
struct AlbumQueueTrackEntry: Identifiable {
    let id: Int          // position in trackMap
    let trackTitle: String
    let albumTitle: String
    let isCurrent: Bool
}

/// Diagnostics snapshot for the debug overlay.
struct AlbumQueueDiagnostics {
    let isActive: Bool
    let gridAlbumCount: Int
    let currentBatchAlbums: [String]
    let currentAlbumTitle: String?
    let trackPosition: Int
    let trackCount: Int
    let shouldPrefetch: Bool
    let nextBatchReady: Bool
    let batchExhausted: Bool
    let trackQueue: [AlbumQueueTrackEntry]
}

/// Pure logic for managing auto-advance album queues.
///
/// Tracks which albums are in the current batch, maps track titles to albums,
/// and determines when to pre-fetch and swap in the next batch.
/// No MusicKit player dependency — PlaybackViewModel owns the player
/// and bridges results from this manager to observable state.
final class AlbumQueueManager {

    // MARK: - State

    /// Full album list from the grid (Crate Wall, genre feed, or artist catalog).
    private(set) var gridAlbums: [CrateAlbum] = []

    /// Index of the album the user tapped in the grid.
    private(set) var anchorIndex: Int = 0

    /// Albums currently loaded in the player queue.
    private(set) var currentBatch: [CrateAlbum] = []

    /// Ordered track-to-album mapping for the current batch.
    private(set) var trackMap: [(title: String, albumID: MusicItemID)] = []

    /// Forward-search cursor in trackMap — handles duplicate titles like "Intro".
    private(set) var currentTrackPosition: Int = 0

    /// Which album is currently playing.
    private(set) var currentAlbum: CrateAlbum?

    /// True when playing the last album of the current batch.
    private(set) var shouldPrefetch: Bool = false

    /// Pre-fetched next batch, waiting to swap in.
    private(set) var nextBatch: (albums: [CrateAlbum], trackMap: [(title: String, albumID: MusicItemID)])?

    /// True after setPendingQueue, consumed by computeBatch.
    private(set) var hasPendingQueue: Bool = false

    /// True when the current batch has been fully exhausted.
    private(set) var batchExhausted: Bool = false

    // MARK: - Configuration

    /// Number of albums to include after the anchor in each batch.
    static let batchSize = 4

    // MARK: - Methods

    /// Called on grid tap — stores the grid context for later use when playback starts.
    func setPendingQueue(gridAlbums: [CrateAlbum], tappedIndex: Int) {
        reset()
        self.gridAlbums = gridAlbums
        self.anchorIndex = tappedIndex
        self.hasPendingQueue = true
    }

    /// Returns the initial batch: anchor album + next N albums from the grid.
    /// Consumes the pending queue flag.
    func computeBatch() -> [CrateAlbum] {
        hasPendingQueue = false
        let start = anchorIndex
        let end = min(start + Self.batchSize + 1, gridAlbums.count)
        let batch = Array(gridAlbums[start..<end])
        currentBatch = batch
        return batch
    }

    /// Consumes the pending queue for anchor-phase playback.
    /// Sets currentBatch to just the anchor album (played immediately).
    /// Returns the anchor and remaining albums (fetched in background).
    func consumePendingQueue() -> (anchor: CrateAlbum, remaining: [CrateAlbum]) {
        hasPendingQueue = false
        let start = anchorIndex
        let end = min(start + Self.batchSize + 1, gridAlbums.count)
        let allBatch = Array(gridAlbums[start..<end])
        currentBatch = [allBatch[0]]
        return (anchor: allBatch[0], remaining: Array(allBatch.dropFirst()))
    }

    /// Appends additional albums and their tracks to the current batch.
    /// Called when background-fetched albums are ready while the anchor is still playing.
    func appendToBatch(albums: [CrateAlbum], tracksByAlbum: [(albumID: MusicItemID, titles: [String])]) {
        currentBatch.append(contentsOf: albums)
        let newEntries = tracksByAlbum.flatMap { entry in
            entry.titles.map { (title: $0, albumID: entry.albumID) }
        }
        trackMap.append(contentsOf: newEntries)
        updateShouldPrefetch()
    }

    /// Builds the trackMap from fetched track titles, ordered by album then track.
    /// - Parameter tracksByAlbum: Array of (albumID, track titles) in album order.
    func registerBatchTracks(_ tracksByAlbum: [(albumID: MusicItemID, titles: [String])]) {
        trackMap = tracksByAlbum.flatMap { entry in
            entry.titles.map { (title: $0, albumID: entry.albumID) }
        }
        currentTrackPosition = 0
        batchExhausted = false

        // Set current album to the first batch album.
        if let firstAlbumID = tracksByAlbum.first?.albumID {
            currentAlbum = currentBatch.first(where: { $0.id == firstAlbumID })
        }

        // Check if only one album in batch — prefetch immediately.
        updateShouldPrefetch()
    }

    /// Called when the player's current track changes.
    /// Searches forward in trackMap from currentTrackPosition to handle duplicate titles.
    /// - Parameters:
    ///   - title: Title of the new track.
    ///   - checkBackward: When true and forward search fails, checks one position back.
    ///     Used for skip-backward which moves one track at a time. Deliberately one-back
    ///     only (not a full backward scan) so queue-wrap detection still works — wraps
    ///     jump from position N-1 to 0, which is more than one step back.
    /// - Returns: Whether the track was found, whether the album changed, and the new album if so.
    ///   `found: false` while `isAtLastTrack` is true indicates the queue wrapped — batch is done.
    func trackDidChange(to title: String, checkBackward: Bool = false) -> (found: Bool, albumChanged: Bool, newAlbum: CrateAlbum?) {
        guard !trackMap.isEmpty else {
            return (found: false, albumChanged: false, newAlbum: nil)
        }

        // Search forward from current position.
        var found = false
        for i in currentTrackPosition..<trackMap.count {
            if trackMap[i].title == title {
                currentTrackPosition = i
                found = true
                break
            }
        }

        // If not found forward and checkBackward is enabled, check one position back.
        // One-back only: skip-backward moves one track at a time, but queue wraps
        // jump from N-1 → 0 (more than one step), so this won't interfere with wrap detection.
        if !found && checkBackward {
            let oneBack = currentTrackPosition - 1
            if oneBack >= 0 && trackMap[oneBack].title == title {
                currentTrackPosition = oneBack
                found = true
            }
        }

        // If still not found, the queue likely wrapped back to an earlier track.
        guard found else {
            return (found: false, albumChanged: false, newAlbum: nil)
        }

        let entry = trackMap[currentTrackPosition]
        let previousAlbum = currentAlbum
        let newAlbum = currentBatch.first(where: { $0.id == entry.albumID })
        currentAlbum = newAlbum

        updateShouldPrefetch()

        let albumChanged = previousAlbum?.id != newAlbum?.id
        return (found: true, albumChanged: albumChanged, newAlbum: albumChanged ? newAlbum : nil)
    }

    /// Jumps the track cursor to an absolute position in the trackMap.
    /// Used when a track-list tap replays the existing queue at a known index.
    func seekToTrack(at index: Int) {
        guard index >= 0 && index < trackMap.count else { return }
        currentTrackPosition = index
        let entry = trackMap[index]
        currentAlbum = currentBatch.first(where: { $0.id == entry.albumID })
        updateShouldPrefetch()
    }

    /// True when the track cursor is at the last entry in the trackMap.
    var isAtLastTrack: Bool {
        !trackMap.isEmpty && currentTrackPosition >= trackMap.count - 1
    }

    /// Signals that the current batch has finished playing (no more tracks).
    func markBatchExhausted() {
        batchExhausted = true
    }

    /// Returns the next batch of albums after the current batch, or nil if the grid is exhausted.
    func computeNextBatch() -> [CrateAlbum]? {
        guard !currentBatch.isEmpty else { return nil }

        // Find where the current batch ends in the grid.
        guard let lastBatchAlbum = currentBatch.last,
              let lastIndex = gridAlbums.firstIndex(where: { $0.id == lastBatchAlbum.id }) else {
            return nil
        }

        let nextStart = lastIndex + 1
        guard nextStart < gridAlbums.count else { return nil }

        let nextEnd = min(nextStart + Self.batchSize + 1, gridAlbums.count)
        return Array(gridAlbums[nextStart..<nextEnd])
    }

    /// Stores a pre-fetched next batch, ready to swap in when the current batch exhausts.
    func registerNextBatch(albums: [CrateAlbum], tracksByAlbum: [(albumID: MusicItemID, titles: [String])]) {
        let map = tracksByAlbum.flatMap { entry in
            entry.titles.map { (title: $0, albumID: entry.albumID) }
        }
        nextBatch = (albums: albums, trackMap: map)
    }

    /// Swaps the next batch into current. Returns false if no next batch is available.
    func advanceToNextBatch() -> Bool {
        guard let next = nextBatch else { return false }
        currentBatch = next.albums
        trackMap = next.trackMap
        currentTrackPosition = 0
        batchExhausted = false
        nextBatch = nil

        // Set current album to first in new batch.
        if let firstEntry = trackMap.first {
            currentAlbum = currentBatch.first(where: { $0.id == firstEntry.albumID })
        }

        updateShouldPrefetch()
        return true
    }

    /// Clears all state.
    func reset() {
        gridAlbums = []
        anchorIndex = 0
        currentBatch = []
        trackMap = []
        currentTrackPosition = 0
        currentAlbum = nil
        shouldPrefetch = false
        nextBatch = nil
        hasPendingQueue = false
        batchExhausted = false
    }

    /// Current diagnostics snapshot for the debug overlay.
    var diagnostics: AlbumQueueDiagnostics {
        // Build album ID → title lookup for track queue entries.
        let albumLookup = Dictionary(uniqueKeysWithValues: currentBatch.map { ($0.id, $0.title) })

        let queue = trackMap.enumerated().map { index, entry in
            AlbumQueueTrackEntry(
                id: index,
                trackTitle: entry.title,
                albumTitle: albumLookup[entry.albumID] ?? "Unknown",
                isCurrent: index == currentTrackPosition
            )
        }

        return AlbumQueueDiagnostics(
            isActive: !currentBatch.isEmpty,
            gridAlbumCount: gridAlbums.count,
            currentBatchAlbums: currentBatch.map(\.title),
            currentAlbumTitle: currentAlbum?.title,
            trackPosition: currentTrackPosition,
            trackCount: trackMap.count,
            shouldPrefetch: shouldPrefetch,
            nextBatchReady: nextBatch != nil,
            batchExhausted: batchExhausted,
            trackQueue: queue
        )
    }

    // MARK: - Private

    private func updateShouldPrefetch() {
        guard let lastBatchAlbum = currentBatch.last else {
            shouldPrefetch = false
            return
        }
        shouldPrefetch = currentAlbum?.id == lastBatchAlbum.id
    }
}
