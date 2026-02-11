import SwiftUI
import Combine
import MusicKit

/// A thin progress bar showing track progress with a gradient fill
/// derived from album artwork colors. Draggable for scrubbing.
struct PlaybackProgressBar: View {

    @Environment(PlaybackViewModel.self) private var viewModel
    @State private var colorExtractor = ArtworkColorExtractor()
    @State private var isDragging = false
    @State private var scrubProgress: Double = 0
    @State private var currentTime: TimeInterval = 0

    private let restHeight: CGFloat = 4
    private let expandedHeight: CGFloat = 8
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = currentProgress
            let barHeight = isDragging ? expandedHeight : restHeight

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
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if !isDragging {
                            withAnimation(.spring(response: 0.2)) {
                                isDragging = true
                            }
                            fireHaptic()
                        }
                        scrubProgress = min(max(value.location.x / width, 0), 1)
                    }
                    .onEnded { value in
                        let finalProgress = min(max(value.location.x / width, 0), 1)
                        if let duration = viewModel.trackDuration, duration > 0 {
                            viewModel.seek(to: finalProgress * duration)
                        }
                        withAnimation(.spring(response: 0.2)) {
                            isDragging = false
                        }
                    }
            )
            .animation(.spring(response: 0.2), value: isDragging)
        }
        .frame(height: isDragging ? expandedHeight : restHeight)
        .animation(.spring(response: 0.2), value: isDragging)
        .onReceive(timer) { _ in
            if !isDragging {
                currentTime = viewModel.playbackTime
            }
        }
        .task(id: viewModel.nowPlayingArtwork) {
            await colorExtractor.extract(from: viewModel.nowPlayingArtwork)
        }
    }

    // MARK: - Private

    private var currentProgress: Double {
        if isDragging {
            return scrubProgress
        }
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

    private func fireHaptic() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}
