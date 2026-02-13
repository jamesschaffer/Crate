import MusicKit

/// Navigation destination types for the main NavigationStack.
enum CrateDestination: Hashable {
    case album(CrateAlbum)
    case artist(name: String, albumID: MusicItemID)
}
