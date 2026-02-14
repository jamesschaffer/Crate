import Testing
import MusicKit
@testable import Crate_iOS

/// Tests for AlbumQueueManager's pure queue logic.
struct AlbumQueueManagerTests {

    /// Helper to create test albums with unique IDs.
    private func makeAlbum(id: String, title: String? = nil) -> CrateAlbum {
        CrateAlbum(
            id: MusicItemID(id),
            title: title ?? "Album \(id)",
            artistName: "Artist \(id)",
            artworkURL: nil,
            releaseDate: nil,
            genreNames: ["Rock"]
        )
    }

    /// Helper to build a grid of N albums.
    private func makeGrid(count: Int) -> [CrateAlbum] {
        (1...count).map { makeAlbum(id: "\($0)") }
    }

    // MARK: - Test 1: setPendingQueue stores grid albums and tapped index

    @Test("setPendingQueue stores grid albums and tapped index")
    func setPendingQueueStoresState() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 10)

        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 3)

        #expect(manager.gridAlbums.count == 10)
        #expect(manager.anchorIndex == 3)
        #expect(manager.hasPendingQueue == true)
    }

    // MARK: - Test 2: computeBatch returns anchor + next 4

    @Test("computeBatch returns anchor + next 4 albums")
    func computeBatchReturnsFive() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 10)

        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 2)
        let batch = manager.computeBatch()

        #expect(batch.count == 5)
        #expect(batch[0].id == MusicItemID("3"))
        #expect(batch[4].id == MusicItemID("7"))
        #expect(manager.hasPendingQueue == false)
    }

    // MARK: - Test 3: computeBatch with fewer than 4 remaining returns partial

    @Test("computeBatch with fewer than 4 remaining returns partial batch")
    func computeBatchPartial() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)

        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 3)
        let batch = manager.computeBatch()

        #expect(batch.count == 2)
        #expect(batch[0].id == MusicItemID("4"))
        #expect(batch[1].id == MusicItemID("5"))
    }

    // MARK: - Test 4: computeBatch at last album returns batch of 1

    @Test("computeBatch at last album returns batch of 1")
    func computeBatchSingle() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)

        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 4)
        let batch = manager.computeBatch()

        #expect(batch.count == 1)
        #expect(batch[0].id == MusicItemID("5"))
    }

    // MARK: - Test 5: registerBatchTracks builds correct ordered trackMap

    @Test("registerBatchTracks builds correct ordered trackMap")
    func registerBatchTracksBuildMap() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B"]),
            (albumID: MusicItemID("2"), titles: ["Track C"]),
        ])

        #expect(manager.trackMap.count == 3)
        #expect(manager.trackMap[0].title == "Track A")
        #expect(manager.trackMap[0].albumID == MusicItemID("1"))
        #expect(manager.trackMap[2].title == "Track C")
        #expect(manager.trackMap[2].albumID == MusicItemID("2"))
    }

    // MARK: - Test 6: registerBatchTracks sets currentAlbum to first batch album

    @Test("registerBatchTracks sets currentAlbum to first batch album")
    func registerBatchTracksSetsCurrentAlbum() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A"]),
            (albumID: MusicItemID("2"), titles: ["Track B"]),
        ])

        #expect(manager.currentAlbum?.id == MusicItemID("1"))
    }

    // MARK: - Test 7: trackDidChange within same album — albumChanged false

    @Test("trackDidChange within same album returns albumChanged false")
    func trackDidChangeSameAlbum() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B", "Track C"]),
            (albumID: MusicItemID("2"), titles: ["Track D"]),
        ])

        let result = manager.trackDidChange(to: "Track B")
        #expect(result.found == true)
        #expect(result.albumChanged == false)
        #expect(result.newAlbum == nil)
        #expect(manager.currentTrackPosition == 1)
    }

    // MARK: - Test 8: trackDidChange crossing boundary — albumChanged true

    @Test("trackDidChange crossing album boundary returns albumChanged true")
    func trackDidChangeCrossBoundary() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A"]),
            (albumID: MusicItemID("2"), titles: ["Track B"]),
        ])

        // Start on album 1.
        _ = manager.trackDidChange(to: "Track A")

        // Cross to album 2.
        let result = manager.trackDidChange(to: "Track B")
        #expect(result.found == true)
        #expect(result.albumChanged == true)
        #expect(result.newAlbum?.id == MusicItemID("2"))
    }

    // MARK: - Test 9: trackDidChange to last album sets shouldPrefetch

    @Test("trackDidChange to last album in batch sets shouldPrefetch")
    func trackDidChangeTriggersPrefetch() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 10)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A"]),
            (albumID: MusicItemID("2"), titles: ["Track B"]),
            (albumID: MusicItemID("3"), titles: ["Track C"]),
            (albumID: MusicItemID("4"), titles: ["Track D"]),
            (albumID: MusicItemID("5"), titles: ["Track E"]),
        ])

        #expect(manager.shouldPrefetch == false)

        // Advance to last album (album 5).
        _ = manager.trackDidChange(to: "Track E")

        #expect(manager.shouldPrefetch == true)
        #expect(manager.currentAlbum?.id == MusicItemID("5"))
    }

    // MARK: - Test 10: trackDidChange past last track signals batch exhaustion
    // (Batch exhaustion is signaled externally via markBatchExhausted)

    @Test("markBatchExhausted sets batchExhausted flag")
    func markBatchExhaustedWorks() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A"]),
        ])

        #expect(manager.batchExhausted == false)
        manager.markBatchExhausted()
        #expect(manager.batchExhausted == true)
    }

    // MARK: - Test 11: trackDidChange with duplicate title resolves forward

    @Test("trackDidChange with duplicate title resolves forward from cursor")
    func trackDidChangeDuplicateTitle() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Intro", "Song A"]),
            (albumID: MusicItemID("2"), titles: ["Intro", "Song B"]),
        ])

        // First "Intro" — album 1.
        let result1 = manager.trackDidChange(to: "Intro")
        #expect(manager.currentTrackPosition == 0)
        #expect(manager.currentAlbum?.id == MusicItemID("1"))

        // Advance past "Song A".
        _ = manager.trackDidChange(to: "Song A")
        #expect(manager.currentTrackPosition == 1)

        // Second "Intro" — should resolve to album 2 (forward search).
        let result2 = manager.trackDidChange(to: "Intro")
        #expect(result2.found == true)
        #expect(manager.currentTrackPosition == 2)
        #expect(result2.albumChanged == true)
        #expect(result2.newAlbum?.id == MusicItemID("2"))
    }

    // MARK: - Test 12: trackDidChange with unknown title — no crash

    @Test("trackDidChange with unknown title returns found false, no crash")
    func trackDidChangeUnknownTitle() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A"]),
        ])

        let result = manager.trackDidChange(to: "Nonexistent Track")
        #expect(result.found == false)
        #expect(result.albumChanged == false)
        #expect(result.newAlbum == nil)
    }

    // MARK: - Test 12b: queue wrap detection — not found + at last track

    @Test("Queue wrap detected: not found + isAtLastTrack")
    func queueWrapDetection() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 10)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B"]),
        ])

        // Advance to last track.
        _ = manager.trackDidChange(to: "Track B")
        #expect(manager.isAtLastTrack == true)

        // Simulate MusicKit wrapping to first track.
        let result = manager.trackDidChange(to: "Track A")
        #expect(result.found == false)
        #expect(manager.isAtLastTrack == true)
    }

    // MARK: - Test 13: computeNextBatch returns correct albums

    @Test("computeNextBatch returns correct albums after current batch")
    func computeNextBatchCorrect() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 15)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        let nextBatch = manager.computeNextBatch()

        #expect(nextBatch != nil)
        #expect(nextBatch?.count == 5)
        #expect(nextBatch?[0].id == MusicItemID("6"))
        #expect(nextBatch?[4].id == MusicItemID("10"))
    }

    // MARK: - Test 14: computeNextBatch at end of grid returns nil

    @Test("computeNextBatch at end of grid returns nil")
    func computeNextBatchEndOfGrid() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 3)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        let nextBatch = manager.computeNextBatch()

        #expect(nextBatch == nil)
    }

    // MARK: - Test 15: registerNextBatch stores data

    @Test("registerNextBatch stores albums and trackMap")
    func registerNextBatchStoresData() {
        let manager = AlbumQueueManager()
        let albums = [makeAlbum(id: "6"), makeAlbum(id: "7")]

        manager.registerNextBatch(
            albums: albums,
            tracksByAlbum: [
                (albumID: MusicItemID("6"), titles: ["Track F"]),
                (albumID: MusicItemID("7"), titles: ["Track G"]),
            ]
        )

        #expect(manager.nextBatch != nil)
        #expect(manager.nextBatch?.albums.count == 2)
        #expect(manager.nextBatch?.trackMap.count == 2)
    }

    // MARK: - Test 16: advanceToNextBatch swaps correctly

    @Test("advanceToNextBatch swaps next batch into current")
    func advanceToNextBatchSwaps() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 15)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A"]),
        ])

        let nextAlbums = [makeAlbum(id: "6"), makeAlbum(id: "7")]
        manager.registerNextBatch(
            albums: nextAlbums,
            tracksByAlbum: [
                (albumID: MusicItemID("6"), titles: ["Track F"]),
                (albumID: MusicItemID("7"), titles: ["Track G"]),
            ]
        )

        let success = manager.advanceToNextBatch()

        #expect(success == true)
        #expect(manager.currentBatch.count == 2)
        #expect(manager.currentBatch[0].id == MusicItemID("6"))
        #expect(manager.trackMap.count == 2)
        #expect(manager.currentTrackPosition == 0)
        #expect(manager.currentAlbum?.id == MusicItemID("6"))
        #expect(manager.nextBatch == nil)
        #expect(manager.batchExhausted == false)
    }

    // MARK: - Test 17: advanceToNextBatch with no next batch returns false

    @Test("advanceToNextBatch with no next batch returns false")
    func advanceToNextBatchNoNext() {
        let manager = AlbumQueueManager()

        let success = manager.advanceToNextBatch()

        #expect(success == false)
    }

    // MARK: - Test 18: reset clears all state

    @Test("reset clears all state")
    func resetClearsState() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 10)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 3)
        _ = manager.computeBatch()
        manager.registerBatchTracks([
            (albumID: MusicItemID("4"), titles: ["Track A"]),
        ])

        manager.reset()

        #expect(manager.gridAlbums.isEmpty)
        #expect(manager.anchorIndex == 0)
        #expect(manager.currentBatch.isEmpty)
        #expect(manager.trackMap.isEmpty)
        #expect(manager.currentTrackPosition == 0)
        #expect(manager.currentAlbum == nil)
        #expect(manager.shouldPrefetch == false)
        #expect(manager.nextBatch == nil)
        #expect(manager.hasPendingQueue == false)
        #expect(manager.batchExhausted == false)
    }

    // MARK: - Test 19: hasPendingQueue lifecycle

    @Test("hasPendingQueue is true after set, false after compute")
    func hasPendingQueueLifecycle() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)

        #expect(manager.hasPendingQueue == false)

        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        #expect(manager.hasPendingQueue == true)

        _ = manager.computeBatch()
        #expect(manager.hasPendingQueue == false)
    }

    // MARK: - Test 20: setPendingQueue again resets prior state

    @Test("setPendingQueue again resets prior state (rule 3)")
    func setPendingQueueResetsState() {
        let manager = AlbumQueueManager()
        let grid1 = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid1, tappedIndex: 2)
        _ = manager.computeBatch()
        manager.registerBatchTracks([
            (albumID: MusicItemID("3"), titles: ["Track A"]),
        ])

        let grid2 = makeGrid(count: 8)
        manager.setPendingQueue(gridAlbums: grid2, tappedIndex: 0)

        #expect(manager.gridAlbums.count == 8)
        #expect(manager.anchorIndex == 0)
        #expect(manager.currentBatch.isEmpty)
        #expect(manager.trackMap.isEmpty)
        #expect(manager.currentAlbum == nil)
        #expect(manager.hasPendingQueue == true)
    }

    // MARK: - Test 22: appendToBatch merges albums and tracks into current batch

    @Test("appendToBatch merges albums and tracks into current batch")
    func appendToBatchMerges() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 10)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)

        // consumePendingQueue sets currentBatch to just the anchor.
        let (anchor, remaining) = manager.consumePendingQueue()
        #expect(manager.currentBatch.count == 1)
        #expect(anchor.id == MusicItemID("1"))

        // Register anchor tracks.
        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B"])
        ])
        #expect(manager.trackMap.count == 2)

        // Append remaining albums.
        let remainingTracks: [(albumID: MusicItemID, titles: [String])] = remaining.map { album in
            (albumID: album.id, titles: ["Track X", "Track Y"])
        }
        manager.appendToBatch(albums: remaining, tracksByAlbum: remainingTracks)

        // currentBatch now has all 5 albums.
        #expect(manager.currentBatch.count == 5)
        // trackMap has anchor's 2 tracks + 4 remaining albums × 2 tracks = 10.
        #expect(manager.trackMap.count == 10)
        // Forward search still works: advance past anchor tracks, find remaining.
        _ = manager.trackDidChange(to: "Track B")
        let result = manager.trackDidChange(to: "Track X")
        #expect(result.found == true)
        #expect(result.albumChanged == true)

        // Diagnostics trackQueue includes all 10 tracks.
        let diag = manager.diagnostics
        #expect(diag.trackQueue.count == 10)
    }

    // MARK: - Test 24: trackDidChange with checkBackward finds one-back track

    @Test("trackDidChange with checkBackward true finds one-back track")
    func trackDidChangeCheckBackwardFinds() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B", "Track C"]),
        ])

        // Advance to Track C (position 2).
        _ = manager.trackDidChange(to: "Track C")
        #expect(manager.currentTrackPosition == 2)

        // Skip backward to Track B — forward search won't find it, but checkBackward will.
        let result = manager.trackDidChange(to: "Track B", checkBackward: true)
        #expect(result.found == true)
        #expect(manager.currentTrackPosition == 1)
    }

    // MARK: - Test 25: trackDidChange without checkBackward does NOT find backward track

    @Test("trackDidChange without checkBackward does NOT find backward track")
    func trackDidChangeNoBackwardSkips() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B", "Track C"]),
        ])

        // Advance to Track C (position 2).
        _ = manager.trackDidChange(to: "Track C")

        // Default checkBackward: false — backward track not found.
        let result = manager.trackDidChange(to: "Track B")
        #expect(result.found == false)
        #expect(manager.currentTrackPosition == 2) // unchanged
    }

    // MARK: - Test 26: checkBackward at last track with wrap title preserves wrap detection

    @Test("checkBackward at last track with wrap title still returns found false")
    func checkBackwardPreservesWrapDetection() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 10)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B"]),
            (albumID: MusicItemID("2"), titles: ["Track C"]),
        ])

        // Advance to last track (position 2).
        _ = manager.trackDidChange(to: "Track C")
        #expect(manager.isAtLastTrack == true)

        // Simulate MusicKit wrapping to "Track A" (position 0).
        // One-back from position 2 is position 1 ("Track B"), not "Track A",
        // so checkBackward still returns found: false.
        let result = manager.trackDidChange(to: "Track A", checkBackward: true)
        #expect(result.found == false)
        #expect(manager.isAtLastTrack == true)
    }

    // MARK: - Test 27: seekToTrack updates position, currentAlbum, and shouldPrefetch

    @Test("seekToTrack updates position, currentAlbum, and shouldPrefetch")
    func seekToTrackUpdatesState() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 10)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B"]),
            (albumID: MusicItemID("2"), titles: ["Track C"]),
            (albumID: MusicItemID("3"), titles: ["Track D"]),
            (albumID: MusicItemID("4"), titles: ["Track E"]),
            (albumID: MusicItemID("5"), titles: ["Track F"]),
        ])

        #expect(manager.currentTrackPosition == 0)
        #expect(manager.currentAlbum?.id == MusicItemID("1"))
        #expect(manager.shouldPrefetch == false)

        // Seek to the last album's track.
        manager.seekToTrack(at: 5) // Track F, album 5
        #expect(manager.currentTrackPosition == 5)
        #expect(manager.currentAlbum?.id == MusicItemID("5"))
        #expect(manager.shouldPrefetch == true) // last album in batch
    }

    // MARK: - Test 28: seekToTrack with out-of-bounds index is a no-op

    @Test("seekToTrack with out-of-bounds index is a no-op")
    func seekToTrackOutOfBoundsNoOp() {
        let manager = AlbumQueueManager()
        let grid = makeGrid(count: 5)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()

        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B"]),
        ])

        manager.seekToTrack(at: 99) // out of bounds — no change
        #expect(manager.currentTrackPosition == 0)
        #expect(manager.currentAlbum?.id == MusicItemID("1"))

        manager.seekToTrack(at: -1) // negative — no change
        #expect(manager.currentTrackPosition == 0)
    }

    // MARK: - Test 23: diagnostics reflects current state

    @Test("diagnostics reflects current state")
    func diagnosticsReflectsState() {
        let manager = AlbumQueueManager()

        // Inactive state.
        var diag = manager.diagnostics
        #expect(diag.isActive == false)
        #expect(diag.gridAlbumCount == 0)

        // Active state.
        let grid = makeGrid(count: 10)
        manager.setPendingQueue(gridAlbums: grid, tappedIndex: 0)
        _ = manager.computeBatch()
        manager.registerBatchTracks([
            (albumID: MusicItemID("1"), titles: ["Track A", "Track B"]),
            (albumID: MusicItemID("2"), titles: ["Track C"]),
        ])

        diag = manager.diagnostics
        #expect(diag.isActive == true)
        #expect(diag.gridAlbumCount == 10)
        #expect(diag.currentBatchAlbums.count == 5)
        #expect(diag.currentAlbumTitle == "Album 1")
        #expect(diag.trackPosition == 0)
        #expect(diag.trackCount == 3)
        #expect(diag.shouldPrefetch == false)
        #expect(diag.nextBatchReady == false)
        #expect(diag.batchExhausted == false)
    }
}
