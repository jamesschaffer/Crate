import SwiftUI

/// Root view for the authorized state. Wraps the main BrowseView in a
/// NavigationStack and overlays the persistent playback footer at the bottom.
struct ContentView: View {

    @State private var navigationPath: [CrateDestination] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            BrowseView(navigationPath: $navigationPath)
        }
        .safeAreaInset(edge: .bottom) {
            PlaybackFooterOverlay(navigationPath: $navigationPath)
        }
        .background { ShaderWarmUpView() }
    }
}

/// Isolates the stateChangeCounter observation so only the footer
/// re-renders on playback state changes, not the entire NavigationStack.
private struct PlaybackFooterOverlay: View {

    @Environment(PlaybackViewModel.self) private var playbackViewModel
    @Binding var navigationPath: [CrateDestination]

    var body: some View {
        let _ = playbackViewModel.stateChangeCounter

        if playbackViewModel.hasQueue && !navigationPath.isEmpty {
            let nowPlayingID = playbackViewModel.nowPlayingAlbum?.id
            let isViewingNowPlaying: Bool = {
                guard let last = navigationPath.last else { return false }
                if case .album(let album, _) = last { return album.id == nowPlayingID }
                return false
            }()
            PlaybackFooterView(showProgressBar: !isViewingNowPlaying, onTap: navigateToNowPlaying)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: playbackViewModel.hasQueue)
        }
    }

    private func navigateToNowPlaying() {
        guard let album = playbackViewModel.nowPlayingAlbum else { return }
        if case .album(let current, _) = navigationPath.last, current.id == album.id { return }
        navigationPath.append(.album(album))
    }
}

/// Invisible 1×1 view that forces Metal to compile the blur + scale shaders
/// at launch. Without this, the first AlbumDetailView push stutters while
/// the GPU compiles shaders on-demand. Renders once, costs nothing ongoing.
private struct ShaderWarmUpView: View {
    var body: some View {
        Color.gray
            .frame(width: 1, height: 1)
            .scaleEffect(3)
            .blur(radius: 60)
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    ContentView()
        .environment(PlaybackViewModel())
}

