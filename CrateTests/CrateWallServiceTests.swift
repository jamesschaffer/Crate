import Testing
import MusicKit
@testable import Crate_iOS

/// Tests for CrateWallService's album generation and filtering.
struct CrateWallServiceTests {

    /// Helper to create test albums with unique IDs.
    private func makeAlbum(id: String, genre: String = "Rock") -> CrateAlbum {
        CrateAlbum(
            id: MusicItemID(id),
            title: "Album \(id)",
            artistName: "Artist \(id)",
            artworkURL: nil,
            releaseDate: nil,
            genreNames: [genre]
        )
    }

    @Test("Wall returns albums from mock service")
    func wallReturnsAlbums() async {
        let mock = MockMusicService()
        let albums = (1...20).map { makeAlbum(id: "\($0)") }
        mock.chartAlbums = albums
        mock.recentlyPlayedAlbums = Array(albums.prefix(5))
        mock.heavyRotationAlbums = Array(albums.prefix(5))
        mock.libraryAlbums = Array(albums.prefix(5))
        mock.recommendationAlbums = Array(albums.prefix(10))
        mock.newReleaseAlbums = Array(albums.suffix(10))

        let service = CrateWallService(musicService: mock)
        let wall = await service.generateWall()

        #expect(!wall.isEmpty)
    }

    @Test("Wall excludes disliked album IDs")
    func wallExcludesDisliked() async {
        let mock = MockMusicService()
        let albums = (1...10).map { makeAlbum(id: "\($0)") }
        mock.chartAlbums = albums
        mock.recentlyPlayedAlbums = albums
        mock.heavyRotationAlbums = albums
        mock.libraryAlbums = albums
        mock.recommendationAlbums = albums
        mock.newReleaseAlbums = albums

        let excludedIDs: Set<String> = ["1", "2", "3"]
        let service = CrateWallService(musicService: mock, excludedAlbumIDs: excludedIDs)
        let wall = await service.generateWall()

        let wallIDs = Set(wall.map(\.id.rawValue))
        for excluded in excludedIDs {
            #expect(!wallIDs.contains(excluded), "Disliked album \(excluded) should be excluded")
        }
    }

    @Test("Empty mock produces empty wall")
    func emptyMockProducesEmptyWall() async {
        let mock = MockMusicService()
        // All arrays default to empty

        let service = CrateWallService(musicService: mock)
        let wall = await service.generateWall()

        #expect(wall.isEmpty)
    }
}
