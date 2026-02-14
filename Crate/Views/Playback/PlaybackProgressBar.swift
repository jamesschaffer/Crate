import SwiftUI
import Combine
import MusicKit

/// A thin progress bar showing track progress with a gradient fill
/// derived from album artwork colors. Visual indicator only (not interactive).
struct PlaybackProgressBar: View {

    @Environment(PlaybackViewModel.self) private var viewModel
    @State private var colorExtractor = ArtworkColorExtractor()
    @State private var currentTime: TimeInterval = 0

    private let barHeight: CGFloat = 4
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

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
        .onReceive(timer) { _ in
            currentTime = viewModel.playbackTime
        }
        .onChange(of: viewModel.trackDuration) { _, newDuration in
            if newDuration != nil {
                currentTime = viewModel.playbackTime
            }
        }
        .task(id: viewModel.nowPlayingArtwork) {
            await colorExtractor.extract(from: viewModel.nowPlayingArtwork)
        }
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
