import SwiftUI

/// macOS-specific keyboard shortcuts for playback control.
///
/// These are added to the app's command menu via the `.commands()` modifier
/// in CrateApp. They provide standard media-like keyboard shortcuts for
/// users who prefer keyboard control.
struct PlaybackCommands: Commands {

    /// Reference to the shared playback view model.
    /// NOTE: In SwiftUI commands, environment injection doesn't work the same
    /// as in views. The view model must be passed in directly.
    let playbackViewModel: PlaybackViewModel

    var body: some Commands {
        CommandMenu("Playback") {
            Button(playbackViewModel.isPlaying ? "Pause" : "Play") {
                Task {
                    await playbackViewModel.togglePlayPause()
                }
            }
            .keyboardShortcut(" ", modifiers: [])

            Divider()

            Button("Next Track") {
                Task {
                    await playbackViewModel.skipToNext()
                }
            }
            .keyboardShortcut(.rightArrow, modifiers: .command)

            Button("Previous Track") {
                Task {
                    await playbackViewModel.skipToPrevious()
                }
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)

            Divider()

            Button("Stop") {
                playbackViewModel.stop()
            }
            .keyboardShortcut(".", modifiers: .command)
        }
    }
}
