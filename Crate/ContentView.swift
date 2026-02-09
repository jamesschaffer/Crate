import SwiftUI

/// Root view for the authorized state. Wraps the main BrowseView in a
/// NavigationStack and overlays the persistent playback footer at the bottom.
struct ContentView: View {

    @Environment(PlaybackViewModel.self) private var playbackViewModel

    var body: some View {
        // Read stateChangeCounter so the view re-renders when the
        // MusicKit player state or queue changes (Combine → counter bump).
        let _ = playbackViewModel.stateChangeCounter

        NavigationStack {
            BrowseView()
        }
        .safeAreaInset(edge: .bottom) {
            if playbackViewModel.hasQueue {
                PlaybackFooterView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: playbackViewModel.hasQueue)
    }
}

#Preview {
    ContentView()
        .environment(PlaybackViewModel())
}
