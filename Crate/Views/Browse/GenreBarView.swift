import SwiftUI

/// Horizontal scrolling bar that transforms between two states:
///
/// **No genre selected:** Dial label pill + genre category pills.
/// **Genre selected:** `[Genre ✕]` pill + subcategory pills.
///
/// Always renders a single row at a constant height — no layout jumps.
/// When the coordinator signals a genre-level transition (`animateGenreBar`),
/// pills stagger-slide downward out of view (exit) then slide up into view
/// (enter), synchronized with the album grid animation.
///
/// Uses vertical `offset` instead of `opacity` or `scaleEffect` because
/// Liquid Glass compositing layers do not support animated opacity and render
/// text/capsule as separate layers that scale independently. Offset applied
/// to both label content and post-glassEffect to handle glass layer bifurcation.
struct GenreBarView: View {

    let dialLabel: String
    let categories: [GenreCategory]
    let selectedCategory: GenreCategory?
    let onSelect: (GenreCategory) -> Void
    var onDialTap: () -> Void = {}
    var onHome: (() -> Void)? = nil
    var selectedSubcategoryIDs: Set<String> = []
    var onToggleSubcategory: ((String) -> Void)? = nil
    var isDisabled: Bool = false

    @Environment(GridTransitionCoordinator.self) private var coordinator
    @State private var pillOffsets: [Int: CGFloat] = [:]
    @State private var staggerTask: Task<Void, Never>?

    /// Distance to slide pills below the bar. Enough to fully hide them.
    private static let slideDistance: CGFloat = 60

    // MARK: - Pill Count

    private var pillCount: Int {
        if let category = selectedCategory {
            return 1 + category.subcategories.count
        } else {
            return 1 + categories.count
        }
    }

    /// Per-pill vertical offset that accounts for animation phase.
    ///
    /// During exit: defaults to 0 (in place) so pills are visible before stagger slides them.
    /// During waiting/entering: defaults to slideDistance (below bar) so new pills enter via stagger.
    /// During idle or non-animated transitions: always 0.
    private func pillOffset(for index: Int) -> CGFloat {
        guard coordinator.animateGenreBar && coordinator.isTransitioning else {
            return 0
        }
        switch coordinator.phase {
        case .exiting:
            return pillOffsets[index] ?? 0
        case .waiting, .entering:
            return pillOffsets[index] ?? Self.slideDistance
        case .idle:
            return 0
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer {
                HStack(spacing: 12) {
                    if let category = selectedCategory {
                        // MARK: Genre-selected state

                        // Selected genre dismiss pill
                        Button {
                            onHome?()
                        } label: {
                            HStack(spacing: 4) {
                                Text(category.name)
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.brandPink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .offset(y: pillOffset(for: 0))
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .offset(y: pillOffset(for: 0))

                        // Subcategory pills
                        ForEach(Array(category.subcategories.enumerated()), id: \.element.id) { index, sub in
                            Button {
                                onToggleSubcategory?(sub.id)
                            } label: {
                                Text(sub.name)
                                    .font(.subheadline)
                                    .fontWeight(selectedSubcategoryIDs.contains(sub.id) ? .semibold : .medium)
                                    .foregroundStyle(selectedSubcategoryIDs.contains(sub.id) ? Color.brandPink : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .offset(y: pillOffset(for: index + 1))
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .offset(y: pillOffset(for: index + 1))
                        }
                    } else {
                        // MARK: Home state

                        // Dial position pill — opens settings
                        Button {
                            onDialTap()
                        } label: {
                            Text(dialLabel)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.brandPink)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .offset(y: pillOffset(for: 0))
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .offset(y: pillOffset(for: 0))

                        // Genre category pills
                        ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                            Button {
                                onSelect(category)
                            } label: {
                                Text(category.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .offset(y: pillOffset(for: index + 1))
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .offset(y: pillOffset(for: index + 1))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .disabled(isDisabled)
                .opacity(isDisabled && !coordinator.animateGenreBar ? 0.6 : 1.0)
            }
        }
        .clipped()
        .onChange(of: coordinator.phase) { _, newPhase in
            guard coordinator.animateGenreBar else { return }
            switch newPhase {
            case .exiting:
                runExitStagger()
            case .entering:
                runEnterStagger()
            case .idle:
                pillOffsets = [:]
            case .waiting:
                break
            }
        }
    }

    // MARK: - Stagger Animations

    private func runExitStagger() {
        staggerTask?.cancel()
        let count = pillCount
        pillOffsets = [:]

        staggerTask = Task { @MainActor in
            let step = count > 1
                ? GridTransition.staggerWindow / Double(count - 1)
                : 0

            for i in 0..<count {
                withAnimation(GridTransition.exitCurve) {
                    pillOffsets[i] = Self.slideDistance
                }
                if i < count - 1 {
                    try? await Task.sleep(for: .seconds(step))
                    if Task.isCancelled { return }
                }
            }
        }
    }

    private func runEnterStagger() {
        staggerTask?.cancel()
        let count = pillCount
        // Ensure all start below the bar.
        for i in 0..<count {
            pillOffsets[i] = Self.slideDistance
        }

        staggerTask = Task { @MainActor in
            // Brief pause so SwiftUI lays out the hidden pills.
            try? await Task.sleep(for: .seconds(GridTransition.phasePause))
            if Task.isCancelled { return }

            let step = count > 1
                ? GridTransition.staggerWindow / Double(count - 1)
                : 0

            for i in 0..<count {
                withAnimation(GridTransition.enterCurve) {
                    pillOffsets[i] = 0
                }
                if i < count - 1 {
                    try? await Task.sleep(for: .seconds(step))
                    if Task.isCancelled { return }
                }
            }
        }
    }
}

#Preview {
    GenreBarView(
        dialLabel: "My Crate",
        categories: GenreTaxonomy.categories,
        selectedCategory: GenreTaxonomy.categories.first,
        onSelect: { _ in }
    )
    .environment(GridTransitionCoordinator())
}
