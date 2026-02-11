import SwiftUI

/// Root view for the authorized state. Wraps the main BrowseView in a
/// NavigationStack and overlays the persistent playback footer at the bottom.
struct ContentView: View {

    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            BrowseView()
        }
        .safeAreaInset(edge: .bottom) {
            PlaybackFooterOverlay(navigationPath: $navigationPath)
        }
    }
}

/// Isolates the stateChangeCounter observation so only the footer
/// re-renders on playback state changes, not the entire NavigationStack.
private struct PlaybackFooterOverlay: View {

    @Environment(PlaybackViewModel.self) private var playbackViewModel
    @Binding var navigationPath: NavigationPath

    var body: some View {
        let _ = playbackViewModel.stateChangeCounter

        if playbackViewModel.hasQueue && !navigationPath.isEmpty {
            PlaybackFooterView(onTap: navigateToNowPlaying)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: playbackViewModel.hasQueue)
        }
    }

    private func navigateToNowPlaying() {
        if let album = playbackViewModel.nowPlayingAlbum {
            navigationPath.append(album)
        }
    }
}

#Preview {
    ContentView()
        .environment(PlaybackViewModel())
}
