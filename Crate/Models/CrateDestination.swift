import MusicKit

/// Grid context for auto-advance playback — stored alongside navigation destination.
struct GridContext: Hashable {
    let albums: [CrateAlbum]
    let tappedIndex: Int
}

/// Navigation destination types for the main NavigationStack.
enum CrateDestination: Hashable {
    case album(CrateAlbum, gridContext: GridContext? = nil)
    case artist(name: String, albumID: MusicItemID)
}
