import Foundation
import MusicKit
@testable import Crate_iOS

/// Errors thrown by MockMusicService for methods that return MusicKit types.
enum MockMusicServiceError: Error {
    case notImplemented
}

/// A configurable mock of MusicServiceProtocol for unit testing.
///
/// Set the `chartAlbums`, `recentlyPlayed`, etc. arrays to control what
/// each method returns. Set `errorToThrow` to simulate network failures.
final class MockMusicService: MusicServiceProtocol, @unchecked Sendable {

    // MARK: - Configurable Returns

    var chartAlbums: [CrateAlbum] = []
    var newReleaseAlbums: [CrateAlbum] = []
    var recentlyPlayedAlbums: [CrateAlbum] = []
    var recommendationAlbums: [CrateAlbum] = []
    var searchResults: [CrateAlbum] = []
    var heavyRotationAlbums: [CrateAlbum] = []
    var libraryAlbums: [CrateAlbum] = []
    var relatedAlbums: [CrateAlbum] = []
    var artistAlbums: [CrateAlbum] = []

    /// If set, all methods will throw this error instead of returning data.
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var searchTerms: [String] = []

    // MARK: - Protocol Implementation

    func fetchChartAlbums(genreID: String, limit: Int, offset: Int) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        return Array(chartAlbums.prefix(limit))
    }

    func fetchNewReleaseChartAlbums(genreID: String, limit: Int, offset: Int) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        return Array(newReleaseAlbums.prefix(limit))
    }

    func fetchRecentlyPlayed(limit: Int) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        return Array(recentlyPlayedAlbums.prefix(limit))
    }

    func fetchRecommendations(limit: Int) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        return Array(recommendationAlbums.prefix(limit))
    }

    func searchAlbums(term: String, limit: Int, offset: Int) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        searchTerms.append(term)
        return Array(searchResults.prefix(limit))
    }

    func fetchAlbumDetail(id: MusicItemID) async throws -> Album? {
        throw MockMusicServiceError.notImplemented
    }

    func fetchAlbumTracks(albumID: MusicItemID) async throws -> MusicItemCollection<Track> {
        throw MockMusicServiceError.notImplemented
    }

    func addToLibrary(albumID: MusicItemID) async throws {
        if let error = errorToThrow { throw error }
    }

    func rateAlbum(id: MusicItemID, rating: LibraryRating) async throws {
        if let error = errorToThrow { throw error }
    }

    func favoriteAlbum(id: MusicItemID) async throws {
        if let error = errorToThrow { throw error }
    }

    func fetchHeavyRotation(limit: Int) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        return Array(heavyRotationAlbums.prefix(limit))
    }

    func fetchLibraryAlbums(limit: Int, offset: Int) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        return Array(libraryAlbums.prefix(limit))
    }

    func fetchRelatedAlbums(for albumID: MusicItemID) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        return relatedAlbums
    }

    func fetchAlbumsByArtist(name: String, limit: Int) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        return Array(artistAlbums.prefix(limit))
    }

    func fetchArtistID(forAlbumID albumID: MusicItemID) async throws -> MusicItemID? {
        if let error = errorToThrow { throw error }
        return nil
    }

    func fetchArtistAlbums(artistID: MusicItemID) async throws -> [CrateAlbum] {
        if let error = errorToThrow { throw error }
        return artistAlbums
    }
}
