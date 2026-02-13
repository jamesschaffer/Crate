import SwiftUI
import Combine
import Observation

#if os(iOS)
import UIKit
#endif

// MARK: - Scrub State Bridge

/// Bridges UIKit gesture state to SwiftUI via Observation.
///
/// @State closures called from UIKit gesture handlers can fail to trigger
/// SwiftUI re-renders. @Observable properties use willSet/didSet that
/// SwiftUI's observation system detects regardless of call site.
@Observable
final class ScrubState {
    var isDragging = false
    var scrubProgress: Double = 0
    var pendingSeekProgress: Double?
}

// MARK: - Scrubber View

/// An interactive scrubber bar for the album detail view.
/// Shows track progress with a gradient fill and supports drag-to-scrub.
///
/// Touch flow:
/// 1. Touch-down → bar expands (animated), progress jumps to touch point (instant)
/// 2. Drag → progress tracks finger in real-time (no animation, 60fps)
/// 3. Touch-up → seek fires, bar contracts (animated)
///
/// On iOS, uses UILongPressGestureRecognizer(minimumPressDuration: 0) to bypass
/// UIScrollView's ~150ms touch delay. Technique from Christian Selig (Apollo)
/// and WWDC 2014 Session 235.
struct PlaybackScrubber: View {

    let gradientColors: (Color, Color)

    @Environment(PlaybackViewModel.self) private var viewModel
    @State private var scrubState = ScrubState()
    @State private var currentTime: TimeInterval = 0
    @State private var lastSeekDate: Date = .distantPast
    @State private var barExpanded = false

    private let restHeight: CGFloat = 6
    private let activeHeight: CGFloat = 14
    private let thumbSize: CGFloat = 20
    private let touchTargetHeight: CGFloat = 54
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = currentProgress
            let barHeight = barExpanded ? activeHeight : restHeight

            ZStack(alignment: .leading) {
                // Unfilled track
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: barHeight)

                // Filled portion — width-based, no mask (faster rendering)
                Capsule()
                    .fill(progressGradient)
                    .frame(width: max(barHeight, progress * width), height: barHeight)

                // Thumb knob — appears on touch for clear scrub feedback
                if barExpanded {
                    Circle()
                        .fill(.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
                        .offset(x: thumbOffset(progress: progress, width: width))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            #if os(iOS)
            .overlay {
                ScrubGestureOverlay(scrubState: scrubState)
            }
            #else
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !scrubState.isDragging {
                            scrubState.isDragging = true
                        }
                        scrubState.scrubProgress = min(max(value.location.x / width, 0), 1)
                    }
                    .onEnded { value in
                        let finalProgress = min(max(value.location.x / width, 0), 1)
                        commitScrub(progress: finalProgress)
                        scrubState.isDragging = false
                    }
            )
            #endif
        }
        .frame(height: touchTargetHeight)
        // Animate ONLY the bar expansion/contraction — not progress changes.
        // Using .onChange + withAnimation instead of .animation(_, value:)
        // because .animation would also animate the progress position jump.
        .onChange(of: scrubState.isDragging) { _, dragging in
            withAnimation(.easeOut(duration: 0.15)) {
                barExpanded = dragging
            }
        }
        .onReceive(timer) { _ in
            if !scrubState.isDragging && lastSeekDate.timeIntervalSinceNow < -1.0 {
                currentTime = viewModel.playbackTime
            }
        }
        #if os(iOS)
        .onChange(of: scrubState.pendingSeekProgress) { _, target in
            if let target {
                commitScrub(progress: target)
                scrubState.pendingSeekProgress = nil
            }
        }
        #endif
    }

    // MARK: - Private

    private func commitScrub(progress: Double) {
        if let duration = viewModel.trackDuration, duration > 0 {
            let seekTime = progress * duration
            currentTime = seekTime
            lastSeekDate = .now
            viewModel.seek(to: seekTime)
        }
    }

    private var currentProgress: Double {
        if scrubState.isDragging {
            return scrubState.scrubProgress
        }
        guard let duration = viewModel.trackDuration, duration > 0 else {
            return 0
        }
        return min(currentTime / duration, 1)
    }

    /// Offset for the thumb circle so its center sits at the progress point,
    /// clamped to stay within the bar bounds.
    private func thumbOffset(progress: Double, width: Double) -> Double {
        let center = progress * width
        let halfThumb = thumbSize / 2
        return min(max(center - halfThumb, 0), width - thumbSize)
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [gradientColors.0, gradientColors.1],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - iOS Gesture Overlay

#if os(iOS)

/// UIKit gesture overlay for instant touch response inside a ScrollView.
///
/// UIScrollView delays content touches by ~150ms to disambiguate scrolling
/// from tapping (`delaysContentTouches`). Gesture recognizers bypass this
/// because they receive touches directly from UIKit's hit-testing pipeline,
/// not through UIScrollView's touch delay mechanism.
///
/// Uses UILongPressGestureRecognizer with minimumPressDuration: 0 because:
/// - UIPanGestureRecognizer has a built-in movement threshold before .began fires
/// - UITapGestureRecognizer only fires on touch-up
/// - UILongPressGestureRecognizer(minimumPressDuration: 0) fires .began immediately
///   on touch-down, and tracks movement via .changed when allowableMovement is set high
///
/// On touch-down, the parent scroll view's pan gesture is temporarily disabled
/// to prevent simultaneous scrolling and scrubbing. Re-enabled on touch-up.
struct ScrubGestureOverlay: UIViewRepresentable {
    let scrubState: ScrubState

    func makeUIView(context: Context) -> ScrubGestureUIView {
        let view = ScrubGestureUIView(scrubState: scrubState)
        return view
    }

    func updateUIView(_ uiView: ScrubGestureUIView, context: Context) {}
}

/// Transparent UIView hosting a zero-delay long-press gesture for scrubbing.
/// Mutates ScrubState directly — SwiftUI's Observation framework detects
/// the property changes and triggers view updates.
final class ScrubGestureUIView: UIView {
    private let scrubState: ScrubState
    private weak var parentScrollView: UIScrollView?

    init(scrubState: ScrubState) {
        self.scrubState = scrubState
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = true

        let gesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleGesture)
        )
        gesture.minimumPressDuration = 0
        gesture.allowableMovement = .greatestFiniteMagnitude
        addGestureRecognizer(gesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil && parentScrollView == nil {
            parentScrollView = findParentScrollView()
        }
    }

    @objc private func handleGesture(_ gesture: UILongPressGestureRecognizer) {
        guard bounds.width > 0 else { return }
        let fraction = min(max(gesture.location(in: self).x / bounds.width, 0), 1)

        switch gesture.state {
        case .began:
            parentScrollView?.panGestureRecognizer.isEnabled = false
            scrubState.isDragging = true
            scrubState.scrubProgress = fraction
            fireHaptic()
        case .changed:
            scrubState.scrubProgress = fraction
        case .ended, .cancelled:
            parentScrollView?.panGestureRecognizer.isEnabled = true
            scrubState.pendingSeekProgress = fraction
            scrubState.isDragging = false
        default:
            break
        }
    }

    private func findParentScrollView() -> UIScrollView? {
        var current: UIView? = superview
        while let view = current {
            if let scrollView = view as? UIScrollView { return scrollView }
            current = view.superview
        }
        return nil
    }

    private func fireHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#endif
