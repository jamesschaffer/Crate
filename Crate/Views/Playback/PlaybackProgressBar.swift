import SwiftUI
import MusicKit

/// A thin progress bar showing track progress with a gradient fill
/// derived from album artwork colors. Visual indicator only (not interactive).
struct PlaybackProgressBar: View {

    @Environment(PlaybackViewModel.self) private var viewModel
    @State private var colorExtractor = ArtworkColorExtractor()
    @State private var currentTime: TimeInterval = 0

    private let barHeight: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = currentProgress

            ZStack(alignment: .leading) {
                // Unfilled track
                Rectangle()
                    .fill(Color.gray.opacity(0.5))

                // Filled portion — gradient stretches full width, masked to progress
                Rectangle()
                    .fill(progressGradient)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: max(0, progress * width))
                    }
            }
            .frame(height: barHeight)
        }
        .frame(height: barHeight)
        .task {
            // Poll playback time every 0.5s. Cancels automatically when
            // this view is removed (unlike Timer.publish which fires globally).
            while !Task.isCancelled {
                currentTime = viewModel.playbackTime
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
        .onChange(of: viewModel.trackDuration) { _, newDuration in
            if newDuration != nil {
                currentTime = viewModel.playbackTime
            }
        }
        .task(id: viewModel.nowPlayingArtwork) {
            await colorExtractor.extract(from: viewModel.nowPlayingArtwork)
        }
        .animation(.easeInOut(duration: 0.3), value: colorExtractor.hasExtracted)
    }

    // MARK: - Private

    private var currentProgress: Double {
        guard let duration = viewModel.trackDuration, duration > 0 else {
            return 0
        }
        return min(currentTime / duration, 1)
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [colorExtractor.colors.0, colorExtractor.colors.1],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
