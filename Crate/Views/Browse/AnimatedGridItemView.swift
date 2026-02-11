import SwiftUI

/// Wrapper around WallGridItemView that applies scale/opacity
/// from the GridTransitionCoordinator during transitions.
///
/// During `.idle` phase, returns 1.0/1.0 — no animation overhead.
struct AnimatedGridItemView: View {

    let album: CrateAlbum
    let index: Int
    @Environment(GridTransitionCoordinator.self) private var coordinator

    var body: some View {
        let state = coordinator.itemStates[index]
        let scale = state?.scale ?? 1.0
        let opacity = state?.opacity ?? 1.0

        WallGridItemView(album: album)
            .scaleEffect(scale)
            .opacity(opacity)
    }
}
