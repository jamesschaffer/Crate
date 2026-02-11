import Foundation
import MusicKit
import Observation
import Combine

/// Wraps ApplicationMusicPlayer to provide reactive playback state
/// and transport controls for the rest of the app.
///
/// Injected into the environment at the app level so any view
/// (mini-player, album detail, etc.) can observe and control playback.
@Observable
final class PlaybackViewModel {

    // MARK: - Player Reference

    private let player = ApplicationMusicPlayer.shared

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

    // MARK: - State Observation

    private var stateObservation: AnyCancellable?
    private var queueObservation: AnyCancellable?

    /// Tracks from the most recent play(tracks:) call, used to look up durations.
    private var currentTracks: MusicItemCollection<Track>?

    // A counter that views can observe to trigger re-renders when player state changes.
    // This is needed because ApplicationMusicPlayer publishes via Combine,
    // and @Observable tracks only direct property mutations.
    var stateChangeCounter: Int = 0

    init() {
        // Always disable shuffle — Crate is about intentional album listening.
        player.state.shuffleMode = .off
        player.state.repeatMode = MusicPlayer.RepeatMode.none

        observePlayerState()
    }

    // MARK: - Transport Controls

    /// Play a specific album starting from the first track (or a given track).
    func play(album: Album) async {
        errorMessage = nil
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
    func play(tracks: MusicItemCollection<Track>, startingAt index: Int = 0) async {
        errorMessage = nil
        currentTracks = tracks
        trackDuration = tracks[index].duration
        do {
            player.queue = ApplicationMusicPlayer.Queue(for: tracks, startingAt: tracks[index])
            try await player.play()
        } catch {
            errorMessage = "Playback failed: \(error.localizedDescription)"
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
        player.stop()
        player.queue = []
    }

    // MARK: - Private

    private func observePlayerState() {
        // Observe player state changes via Combine and bump a counter
        // so @Observable-backed views re-render.
        stateObservation = player.state.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.stateChangeCounter += 1
            }
        }

        queueObservation = player.queue.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.stateChangeCounter += 1
                self?.syncTrackDuration()
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
}
