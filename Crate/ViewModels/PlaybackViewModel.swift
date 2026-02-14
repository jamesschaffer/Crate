import Foundation
import MusicKit
import Observation
import Combine

/// Wraps ApplicationMusicPlayer to provide reactive playback state
/// and transport controls for the rest of the app.
///
/// Injected into the environment at the app level so any view
/// (mini-player, album detail, etc.) can observe and control playback.
@MainActor
@Observable
final class PlaybackViewModel {

    // MARK: - Player Reference

    private let player = ApplicationMusicPlayer.shared

    // MARK: - Dependencies

    private let musicService: MusicServiceProtocol

    // MARK: - Playback State

    /// The CrateAlbum that's currently playing (set when playback starts).
    var nowPlayingAlbum: CrateAlbum?

    /// Title of the currently playing entry.
    var nowPlayingTitle: String? {
        player.queue.currentEntry?.title
    }

    /// Subtitle (artist) of the currently playing entry.
    var nowPlayingSubtitle: String? {
        player.queue.currentEntry?.subtitle
    }

    /// Artwork of the currently playing entry.
    var nowPlayingArtwork: Artwork? {
        player.queue.currentEntry?.artwork
    }

    /// Current playback status.
    var playbackStatus: MusicPlayer.PlaybackStatus {
        player.state.playbackStatus
    }

    /// Whether something is actively playing.
    var isPlaying: Bool {
        playbackStatus == .playing
    }

    /// Current playback time in seconds.
    var playbackTime: TimeInterval {
        player.playbackTime
    }

    /// True if there's anything in the queue.
    var hasQueue: Bool {
        player.queue.currentEntry != nil
    }

    /// Duration of the currently playing track in seconds.
    var trackDuration: TimeInterval?

    /// Human-readable error if playback fails.
    var errorMessage: String?

    /// True while fetching batch tracks before playback starts (shows spinner).
    var isPreparingQueue = false

    // MARK: - Auto-Advance

    /// Manages queue logic for auto-advancing through grid albums.
    let queueManager = AlbumQueueManager()

    /// True when the user explicitly stopped playback (prevents auto-advance).
    private var userDidStop = false

    /// True while we're in the process of swapping to the next batch.
    private var isAdvancing = false

    /// Background task for pre-fetching the NEXT batch of album tracks.
    private var prefetchTask: Task<Void, Never>?

    /// Actual MusicKit Track objects for the next batch, ready to load into the player.
    private var readyBatchTracks: [Track] = []

    // MARK: - State Observation

    private var stateObservation: AnyCancellable?
    private var queueObservation: AnyCancellable?

    /// Tracks from the most recent play(tracks:) call, used to look up durations.
    private var currentTracks: MusicItemCollection<Track>?

    // A counter that views can observe to trigger re-renders when player state changes.
    // This is needed because ApplicationMusicPlayer publishes via Combine,
    // and @Observable tracks only direct property mutations.
    var stateChangeCounter: Int = 0

    init(musicService: MusicServiceProtocol = MusicService()) {
        self.musicService = musicService

        // Always disable shuffle — Crate is about intentional album listening.
        player.state.shuffleMode = .off
        player.state.repeatMode = MusicPlayer.RepeatMode.none

        observePlayerState()
    }

    // MARK: - Grid Context

    /// Called by grid views when the user taps an album tile.
    /// Stores the grid context so auto-advance activates when playback starts.
    func setGridContext(gridAlbums: [CrateAlbum], tappedIndex: Int) {
        print("[Crate][Queue] setGridContext: \(gridAlbums.count) albums, tapped index \(tappedIndex)")
        queueManager.setPendingQueue(gridAlbums: gridAlbums, tappedIndex: tappedIndex)
    }

    // MARK: - Transport Controls

    /// Play a specific album starting from the first track (or a given track).
    func play(album: Album) async {
        errorMessage = nil
        resetAutoAdvance()
        currentTracks = nil
        trackDuration = nil
        do {
            player.queue = [album]
            try await player.play()
        } catch {
            errorMessage = "Playback failed: \(error.localizedDescription)"
        }
    }

    /// Play a collection of tracks (e.g., from an album's track list).
    ///
    /// Three paths:
    /// 1. **Within-batch tap:** Album is already in the current batch — reuse existing
    ///    tracks, rebuild the queue at the tapped position, preserve auto-advance.
    /// 2. **Preloader (pending queue):** First play from grid — fetch all batch tracks
    ///    upfront, build one complete queue, start playback.
    /// 3. **Normal play:** No grid context — single-album playback, reset auto-advance.
    func play(tracks: MusicItemCollection<Track>, startingAt index: Int = 0, from album: CrateAlbum? = nil) async {
        errorMessage = nil
        userDidStop = false

        // Path 1: Within-batch track tap — album already loaded, reuse currentTracks.
        // Preserves auto-advance (no resetAutoAdvance, no refetch, no spinner).
        if let album,
           !queueManager.currentBatch.isEmpty,
           queueManager.currentBatch.contains(where: { $0.id == album.id }),
           let existingTracks = currentTracks {

            // Find the tapped track's position in the full batch queue.
            let tappedTrack = tracks[index]
            let batchIndex = existingTracks.firstIndex(where: { $0.id == tappedTrack.id })

            trackDuration = tappedTrack.duration
            do {
                player.queue = ApplicationMusicPlayer.Queue(for: existingTracks, startingAt: tappedTrack)
                try await player.play()
                nowPlayingAlbum = album
                if let batchIndex {
                    let batchPosition = existingTracks.distance(from: existingTracks.startIndex, to: batchIndex)
                    queueManager.seekToTrack(at: batchPosition)
                }
                print("[Crate][Queue] Within-batch tap: '\(tappedTrack.title)' on '\(album.title)'")
            } catch {
                errorMessage = "Playback failed: \(error.localizedDescription)"
            }
            return
        }

        if queueManager.hasPendingQueue {
            // Auto-advance mode: load ALL batch tracks, then play everything at once.
            let batch = queueManager.computeBatch()
            let remaining = Array(batch.dropFirst())
            print("[Crate][Queue] play(tracks:) — preparing \(batch.count)-album queue")

            // Start with the anchor's tracks (already fetched by AlbumDetailViewModel).
            var allTracks = Array(tracks)
            var tracksByAlbum: [(albumID: MusicItemID, titles: [String])] = [
                (albumID: batch[0].id, titles: tracks.map(\.title))
            ]

            // Fetch remaining batch albums' tracks before playing anything.
            if !remaining.isEmpty {
                isPreparingQueue = true
                for (i, album) in remaining.enumerated() {
                    if i > 0 {
                        try? await Task.sleep(for: .milliseconds(500))
                    }
                    do {
                        let fetched = try await musicService.fetchAlbumTracks(albumID: album.id)
                        tracksByAlbum.append((albumID: album.id, titles: fetched.map(\.title)))
                        allTracks.append(contentsOf: fetched)
                        print("[Crate][Queue] Fetched \(fetched.count) tracks for '\(album.title)'")
                    } catch {
                        print("[Crate][Queue] Failed to fetch tracks for '\(album.title)': \(error)")
                    }
                }
            }

            // Register all batch tracks with the queue manager.
            queueManager.registerBatchTracks(tracksByAlbum)

            // Build and play the complete queue in one shot.
            let collection = MusicItemCollection(allTracks)
            currentTracks = collection
            trackDuration = allTracks[index].duration

            do {
                player.queue = ApplicationMusicPlayer.Queue(for: collection, startingAt: tracks[index])
                try await player.play()
                nowPlayingAlbum = album ?? batch.first
                print("[Crate][Queue] Playing \(allTracks.count) tracks from \(batch.count) albums")
            } catch {
                errorMessage = "Playback failed: \(error.localizedDescription)"
                queueManager.reset()
            }

            isPreparingQueue = false
        } else {
            // Normal play — reset any active auto-advance.
            print("[Crate][Queue] play(tracks:) — normal playback (no grid context)")
            resetAutoAdvance()
            currentTracks = tracks
            trackDuration = tracks[index].duration
            do {
                player.queue = ApplicationMusicPlayer.Queue(for: tracks, startingAt: tracks[index])
                try await player.play()
                if let album { nowPlayingAlbum = album }
            } catch {
                errorMessage = "Playback failed: \(error.localizedDescription)"
            }
        }
    }

    /// Toggle play/pause.
    func togglePlayPause() async {
        if isPlaying {
            player.pause()
        } else {
            do {
                try await player.play()
            } catch {
                errorMessage = "Could not resume playback: \(error.localizedDescription)"
            }
        }
    }

    /// Skip to the next track.
    func skipToNext() async {
        do {
            try await player.skipToNextEntry()
        } catch {
            errorMessage = "Could not skip forward: \(error.localizedDescription)"
        }
    }

    /// Skip to the previous track.
    func skipToPrevious() async {
        do {
            try await player.skipToPreviousEntry()
        } catch {
            errorMessage = "Could not skip back: \(error.localizedDescription)"
        }
    }

    /// Seek to a specific time in the current track.
    func seek(to time: TimeInterval) {
        player.playbackTime = time
    }

    /// Stop playback and clear the queue.
    func stop() {
        userDidStop = true
        resetAutoAdvance()
        player.stop()
        player.queue = []
    }

    // MARK: - Private — Observation

    private func observePlayerState() {
        // Observe player state changes via Combine and bump a counter
        // so @Observable-backed views re-render.
        stateObservation = player.state.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.stateChangeCounter += 1
                self.checkBatchExhausted()
            }
        }

        queueObservation = player.queue.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.stateChangeCounter += 1
                self.syncTrackDuration()
                self.handleTrackChange()
            }
        }
    }

    /// Match the current queue entry against stored tracks to update duration.
    private func syncTrackDuration() {
        guard let title = player.queue.currentEntry?.title,
              let tracks = currentTracks else {
            return
        }
        if let match = tracks.first(where: { $0.title == title }) {
            trackDuration = match.duration
        }
    }

    // MARK: - Private — Auto-Advance

    /// Check if the current batch is exhausted and advance to the next one.
    /// Handles two MusicKit behaviors:
    /// 1. Classic: player stopped with empty queue (currentEntry == nil).
    /// 2. Queue wrap: MusicKit wraps back to the first entry and pauses instead of stopping.
    ///    Detected by checking if we were on the last track and the current entry can't be
    ///    found forward in the trackMap (it wrapped backwards).
    private func checkBatchExhausted() {
        guard !isAdvancing,
              !userDidStop,
              !queueManager.currentBatch.isEmpty else { return }

        let status = player.state.playbackStatus

        // Classic case: player stopped with empty queue.
        if status == .stopped && player.queue.currentEntry == nil {
            triggerBatchAdvance()
            return
        }

        // MusicKit wrap case: player paused/stopped while we were on the last track.
        // If the current entry title can't be found forward from the last position,
        // the queue wrapped — batch is done.
        // Note: if the user manually paused on the last track, trackDidChange finds
        // it at the same position (found: true) so no false trigger.
        if status != .playing && queueManager.isAtLastTrack {
            if let title = player.queue.currentEntry?.title {
                let result = queueManager.trackDidChange(to: title)
                if !result.found {
                    triggerBatchAdvance()
                }
            }
        }
    }

    /// Fetch tracks for a set of albums and store as the ready batch (for pre-fetch of future batches).
    /// Includes a delay between requests to avoid Apple Music API rate limits.
    private func fetchReadyBatch(albums: [CrateAlbum]) async {
        var tracksByAlbum: [(albumID: MusicItemID, titles: [String])] = []
        var allTracks: [Track] = []

        for (index, album) in albums.enumerated() {
            guard !Task.isCancelled else { return }

            // Throttle: wait between requests to avoid rate limiting.
            if index > 0 {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
            }

            do {
                let tracks = try await musicService.fetchAlbumTracks(albumID: album.id)
                tracksByAlbum.append((albumID: album.id, titles: tracks.map(\.title)))
                allTracks.append(contentsOf: tracks)
            } catch {
                print("[Crate] Failed to fetch tracks for batch album \(album.title): \(error)")
            }
        }

        guard !Task.isCancelled else { return }
        queueManager.registerNextBatch(albums: albums, tracksByAlbum: tracksByAlbum)
        readyBatchTracks = allTracks
    }

    /// Swap in the next batch and start playing.
    private func playNextBatch() async {
        guard queueManager.advanceToNextBatch() else {
            // Grid exhausted — no more albums.
            queueManager.reset()
            return
        }

        guard !readyBatchTracks.isEmpty else {
            print("[Crate] Next batch has no tracks")
            queueManager.reset()
            return
        }

        let tracks = readyBatchTracks
        readyBatchTracks = []
        let collection = MusicItemCollection(tracks)
        currentTracks = collection
        trackDuration = tracks.first?.duration

        do {
            player.queue = ApplicationMusicPlayer.Queue(for: collection)
            try await player.play()
            nowPlayingAlbum = queueManager.currentAlbum
        } catch {
            print("[Crate] Failed to play next batch: \(error)")
            queueManager.reset()
        }
    }

    /// Handle track changes from the queue observer — update album tracking and trigger pre-fetch.
    private func handleTrackChange() {
        guard !queueManager.currentBatch.isEmpty else { return }

        // If currentEntry became nil, check for batch exhaustion.
        guard let title = player.queue.currentEntry?.title else {
            if queueManager.isAtLastTrack && !isAdvancing && !userDidStop {
                triggerBatchAdvance()
            }
            return
        }

        let result = queueManager.trackDidChange(to: title, checkBackward: true)

        // Queue wrap detection: track not found forward + we were on the last track.
        // MusicKit wraps the queue to the first entry instead of clearing it,
        // so this is how we detect "album/batch finished."
        if !result.found && queueManager.isAtLastTrack && !isAdvancing && !userDidStop {
            triggerBatchAdvance()
            return
        }

        if result.albumChanged, let newAlbum = result.newAlbum {
            nowPlayingAlbum = newAlbum
        }

        // If we're on the last album of the batch, pre-fetch the next batch.
        if queueManager.shouldPrefetch && queueManager.nextBatch == nil {
            prefetchTask?.cancel()
            prefetchTask = Task { [weak self] in
                await self?.prefetchNextBatch()
            }
        }
    }

    /// Trigger the batch advance sequence.
    private func triggerBatchAdvance() {
        queueManager.markBatchExhausted()
        isAdvancing = true

        Task { [weak self] in
            await self?.playNextBatch()
            self?.isAdvancing = false
        }
    }

    /// Pre-fetch the next batch of albums from the grid.
    private func prefetchNextBatch() async {
        guard let nextAlbums = queueManager.computeNextBatch() else { return }
        await fetchReadyBatch(albums: nextAlbums)
    }

    /// Reset all auto-advance state.
    private func resetAutoAdvance() {
        prefetchTask?.cancel()
        prefetchTask = nil
        readyBatchTracks = []
        queueManager.reset()
    }
}
