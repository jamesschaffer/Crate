import Foundation
import Testing
import SwiftData
@testable import Crate_iOS

/// Tests for DislikeService CRUD operations and DislikedAlbum model.
///
/// Uses an in-memory SwiftData ModelContainer so tests don't touch disk.
struct DislikeServiceTests {

    /// Create an in-memory container with both models for testing.
    private func makeContext() throws -> ModelContext {
        let schema = Schema([FavoriteAlbum.self, DislikedAlbum.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("DislikedAlbum model initializes correctly")
    func modelInit() {
        let disliked = DislikedAlbum(
            albumID: "99999",
            title: "Bad Album",
            artistName: "Bad Artist",
            artworkURL: "https://example.com/art.jpg"
        )

        #expect(disliked.albumID == "99999")
        #expect(disliked.title == "Bad Album")
        #expect(disliked.artistName == "Bad Artist")
        #expect(disliked.artworkURL == "https://example.com/art.jpg")
        #expect(disliked.dateAdded <= Date.now)
    }

    @Test("Add and check dislike")
    @MainActor
    func addAndCheck() throws {
        let ctx = try makeContext()
        let service = DislikeService(modelContext: ctx)

        #expect(!service.isDisliked(albumID: "123"))

        service.addDislike(albumID: "123", title: "Test", artistName: "Artist", artworkURL: nil)

        #expect(service.isDisliked(albumID: "123"))
    }

    @Test("Remove dislike")
    @MainActor
    func removeDislike() throws {
        let ctx = try makeContext()
        let service = DislikeService(modelContext: ctx)

        service.addDislike(albumID: "456", title: "Test", artistName: "Artist", artworkURL: nil)
        #expect(service.isDisliked(albumID: "456"))

        service.removeDislike(albumID: "456")
        #expect(!service.isDisliked(albumID: "456"))
    }

    @Test("Fetch all disliked IDs returns correct set")
    @MainActor
    func fetchAllDislikedIDs() throws {
        let ctx = try makeContext()
        let service = DislikeService(modelContext: ctx)

        service.addDislike(albumID: "AAA", title: "A", artistName: "A", artworkURL: nil)
        service.addDislike(albumID: "BBB", title: "B", artistName: "B", artworkURL: nil)
        service.addDislike(albumID: "CCC", title: "C", artistName: "C", artworkURL: nil)

        let ids = service.fetchAllDislikedIDs()
        #expect(ids.count == 3)
        #expect(ids.contains("AAA"))
        #expect(ids.contains("BBB"))
        #expect(ids.contains("CCC"))
    }

    @Test("Disliking same album twice doesn't duplicate")
    @MainActor
    func noDuplicate() throws {
        let ctx = try makeContext()
        let service = DislikeService(modelContext: ctx)

        service.addDislike(albumID: "DUP", title: "Dup", artistName: "Dup", artworkURL: nil)
        service.addDislike(albumID: "DUP", title: "Dup", artistName: "Dup", artworkURL: nil)

        let ids = service.fetchAllDislikedIDs()
        #expect(ids.count == 1)
    }
}
