import Foundation
import Testing
import SwiftData
@testable import Crate_iOS

/// Tests for ReviewService cache layer and AlbumReview model.
///
/// Uses an in-memory SwiftData ModelContainer so tests don't touch disk
/// and are fully isolated. Cloud Function calls are not tested here
/// (requires a live backend).
@MainActor
struct ReviewServiceTests {

    /// Create an in-memory container and service for testing.
    private func makeService() throws -> (ReviewService, ModelContext) {
        let schema = Schema([AlbumReview.self])
        let config = ModelConfiguration("TestReviews", schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)
        let service = ReviewService(modelContext: context)
        return (service, context)
    }

    /// Create a sample review for testing.
    private func sampleReview(albumID: String = "12345") -> AlbumReview {
        AlbumReview(
            albumID: albumID,
            contextSummary: "A landmark album that defined a generation.",
            contextBullets: [
                "Metacritic score: 92/100",
                "Sold over 10 million copies worldwide",
                "Won Album of the Year at the Grammys"
            ],
            rating: 9.2,
            recommendation: "Essential Classic"
        )
    }

    @Test("AlbumReview model initializes with correct values")
    func modelInit() {
        let review = sampleReview()

        #expect(review.albumID == "12345")
        #expect(review.contextSummary == "A landmark album that defined a generation.")
        #expect(review.contextBullets.count == 3)
        #expect(review.rating == 9.2)
        #expect(review.recommendation == "Essential Classic")
        #expect(review.dateGenerated <= Date.now)
    }

    @Test("Cache miss returns nil")
    func cacheMissReturnsNil() throws {
        let (service, _) = try makeService()
        let result = service.cachedReview(albumID: "nonexistent")
        #expect(result == nil)
    }

    @Test("Save and retrieve round-trips correctly")
    func saveAndRetrieve() throws {
        let (service, _) = try makeService()
        let review = sampleReview()

        service.saveReview(review)
        let cached = service.cachedReview(albumID: "12345")

        #expect(cached != nil)
        #expect(cached?.albumID == "12345")
        #expect(cached?.contextSummary == "A landmark album that defined a generation.")
        #expect(cached?.rating == 9.2)
        #expect(cached?.recommendation == "Essential Classic")
        #expect(cached?.contextBullets.count == 3)
    }

    @Test("Save overwrites existing review (upsert)")
    func saveOverwritesExisting() throws {
        let (service, context) = try makeService()

        // Save original
        let original = sampleReview()
        service.saveReview(original)

        // Save replacement
        let replacement = AlbumReview(
            albumID: "12345",
            contextSummary: "Updated summary.",
            contextBullets: ["New bullet"],
            rating: 7.5,
            recommendation: "Genre Staple"
        )
        service.saveReview(replacement)

        // Verify only one review exists and it's the replacement
        let cached = service.cachedReview(albumID: "12345")
        #expect(cached != nil)
        #expect(cached?.contextSummary == "Updated summary.")
        #expect(cached?.rating == 7.5)
        #expect(cached?.recommendation == "Genre Staple")

        // Verify no duplicates
        let descriptor = FetchDescriptor<AlbumReview>()
        let all = try context.fetch(descriptor)
        #expect(all.count == 1)
    }

    @Test("Prompt builds correctly with placeholders")
    func promptBuilding() {
        let prompt = ReviewService.buildPrompt(
            artistName: "Radiohead",
            albumTitle: "OK Computer",
            releaseYear: "1997",
            genres: "Alternative Rock, Art Rock",
            recordLabel: "Parlophone"
        )

        #expect(prompt.contains("Artist: Radiohead"))
        #expect(prompt.contains("Album: OK Computer"))
        #expect(prompt.contains("Year: 1997"))
        #expect(prompt.contains("Genre: Alternative Rock, Art Rock"))
        #expect(prompt.contains("Label: Parlophone"))
        #expect(!prompt.contains("{artistName}"))
        #expect(!prompt.contains("{albumTitle}"))
    }
}
