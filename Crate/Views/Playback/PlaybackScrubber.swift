import SwiftUI
import Combine

/// An interactive scrubber bar for the album detail view.
/// Shows track progress with a gradient fill and supports drag-to-scrub.
/// The visible bar doubles in height on touch for visual feedback,
/// but the outer frame stays fixed so content below never shifts.
struct PlaybackScrubber: View {

    let gradientColors: (Color, Color)

    @Environment(PlaybackViewModel.self) private var viewModel
    @State private var isDragging = false
    @State private var scrubProgress: Double = 0
    @State private var currentTime: TimeInterval = 0

    private let restHeight: CGFloat = 6
    private let activeHeight: CGFloat = 12
    private let touchTargetHeight: CGFloat = 54
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = currentProgress
            let barHeight = isDragging ? activeHeight : restHeight

            ZStack(alignment: .leading) {
                // Unfilled track
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(Color.gray.opacity(0.3))

                // Filled portion
                RoundedRectangle(cornerRadius: barHeight / 2)
                    .fill(progressGradient)
                    .mask(alignment: .leading) {
                        Rectangle()
                            .frame(width: max(0, progress * width))
                    }
            }
            .frame(height: barHeight)
            .animation(.easeInOut(duration: 0.15), value: isDragging)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            fireHaptic()
                        }
                        scrubProgress = min(max(value.location.x / width, 0), 1)
                    }
                    .onEnded { value in
                        let finalProgress = min(max(value.location.x / width, 0), 1)
                        if let duration = viewModel.trackDuration, duration > 0 {
                            viewModel.seek(to: finalProgress * duration)
                        }
                        isDragging = false
                    }
            )
        }
        .frame(height: touchTargetHeight)
        .onReceive(timer) { _ in
            if !isDragging {
                currentTime = viewModel.playbackTime
            }
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
            colors: [gradientColors.0, gradientColors.1],
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
