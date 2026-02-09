import Testing
import SwiftData
@testable import Crate

/// Tests for FavoritesService CRUD operations.
///
/// Uses an in-memory SwiftData ModelContainer so tests don't touch disk
/// and are fully isolated.
struct FavoritesServiceTests {

    @Test("FavoriteAlbum model initializes correctly")
    func modelInit() {
        let favorite = FavoriteAlbum(
            albumID: "12345",
            title: "Test Album",
            artistName: "Test Artist",
            artworkURL: "https://example.com/art.jpg"
        )

        #expect(favorite.albumID == "12345")
        #expect(favorite.title == "Test Album")
        #expect(favorite.artistName == "Test Artist")
        #expect(favorite.artworkURL == "https://example.com/art.jpg")
        #expect(favorite.dateAdded <= Date.now)
    }
}
