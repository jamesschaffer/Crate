import SwiftUI

/// Root view for the authorized state. Wraps the main BrowseView in a
/// NavigationStack and overlays the persistent playback footer at the bottom.
struct ContentView: View {

    @Environment(PlaybackViewModel.self) private var playbackViewModel

    var body: some View {
        NavigationStack {
            BrowseView()
        }
        .safeAreaInset(edge: .bottom) {
            if playbackViewModel.hasQueue {
                PlaybackFooterView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(PlaybackViewModel())
}
