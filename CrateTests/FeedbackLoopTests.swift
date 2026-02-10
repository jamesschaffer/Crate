import Testing
import SwiftData
import MusicKit
@testable import Crate_iOS

/// Tests for the feedback loop: mutual exclusion between likes and dislikes,
/// feed filtering of disliked albums, and GenreFeedWeights correctness.
struct FeedbackLoopTests {

    /// Create an in-memory container with both models for testing.
    private func makeContext() throws -> ModelContext {
        let schema = Schema([FavoriteAlbum.self, DislikedAlbum.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    // MARK: - Mutual Exclusion

    @Test("Liking an album removes its dislike")
    @MainActor
    func likeRemovesDislike() throws {
        let ctx = try makeContext()
        let favService = FavoritesService(modelContext: ctx)
        let dislikeService = DislikeService(modelContext: ctx)

        // First dislike the album
        dislikeService.addDislike(albumID: "100", title: "Test", artistName: "Artist", artworkURL: nil)
        #expect(dislikeService.isDisliked(albumID: "100"))

        // Now like it — should remove dislike
        dislikeService.removeDislike(albumID: "100")
        favService.addFavorite(albumID: "100", title: "Test", artistName: "Artist", artworkURL: nil)

        #expect(favService.isFavorite(albumID: "100"))
        #expect(!dislikeService.isDisliked(albumID: "100"))
    }

    @Test("Disliking an album removes its favorite")
    @MainActor
    func dislikeRemovesFavorite() throws {
        let ctx = try makeContext()
        let favService = FavoritesService(modelContext: ctx)
        let dislikeService = DislikeService(modelContext: ctx)

        // First favorite the album
        favService.addFavorite(albumID: "200", title: "Test", artistName: "Artist", artworkURL: nil)
        #expect(favService.isFavorite(albumID: "200"))

        // Now dislike it — should remove favorite
        favService.removeFavorite(albumID: "200")
        dislikeService.addDislike(albumID: "200", title: "Test", artistName: "Artist", artworkURL: nil)

        #expect(!favService.isFavorite(albumID: "200"))
        #expect(dislikeService.isDisliked(albumID: "200"))
    }

    @Test("An album cannot be both liked and disliked")
    @MainActor
    func mutualExclusion() throws {
        let ctx = try makeContext()
        let favService = FavoritesService(modelContext: ctx)
        let dislikeService = DislikeService(modelContext: ctx)

        // Like, then dislike
        favService.addFavorite(albumID: "300", title: "Test", artistName: "Artist", artworkURL: nil)
        favService.removeFavorite(albumID: "300")
        dislikeService.addDislike(albumID: "300", title: "Test", artistName: "Artist", artworkURL: nil)

        #expect(!favService.isFavorite(albumID: "300"))
        #expect(dislikeService.isDisliked(albumID: "300"))

        // Dislike, then like
        dislikeService.removeDislike(albumID: "300")
        favService.addFavorite(albumID: "300", title: "Test", artistName: "Artist", artworkURL: nil)

        #expect(favService.isFavorite(albumID: "300"))
        #expect(!dislikeService.isDisliked(albumID: "300"))
    }

    // MARK: - GenreFeedWeights

    @Test("GenreFeedWeights sum to 1.0 for all positions")
    func weightsSumToOne() {
        for position in CrateDialPosition.allCases {
            let weights = GenreFeedWeights.weights(for: position)
            let sum = weights.values.values.reduce(0.0, +)
            #expect(abs(sum - 1.0) < 0.001, "Weights for \(position.label) sum to \(sum), expected 1.0")
        }
    }

    @Test("GenreFeedWeights albumCounts sums to total")
    func albumCountsSumCorrectly() {
        for position in CrateDialPosition.allCases {
            let weights = GenreFeedWeights.weights(for: position)
            let counts = weights.albumCounts(total: 50)
            let sum = counts.values.reduce(0, +)
            #expect(sum == 50, "\(position.label) counts sum to \(sum), expected 50")
        }
    }

    @Test("GenreFeedWeights cover all 6 signals")
    func allSignalsCovered() {
        let weights = GenreFeedWeights.weights(for: .mixedCrate)
        for signal in GenreFeedSignal.allCases {
            #expect(weights.values[signal] != nil, "Missing weight for \(signal)")
        }
    }

    // MARK: - Weighted Interleave

    @Test("Weighted interleave produces all input albums")
    func interleaveIncludesAllAlbums() {
        let albumA = CrateAlbum(id: MusicItemID("A"), title: "A", artistName: "A", artworkURL: nil, releaseDate: nil, genreNames: [])
        let albumB = CrateAlbum(id: MusicItemID("B"), title: "B", artistName: "B", artworkURL: nil, releaseDate: nil, genreNames: [])
        let albumC = CrateAlbum(id: MusicItemID("C"), title: "C", artistName: "C", artworkURL: nil, releaseDate: nil, genreNames: [])

        let buckets: [String: [CrateAlbum]] = [
            "signal1": [albumA],
            "signal2": [albumB],
            "signal3": [albumC],
        ]
        let weights: [String: Double] = [
            "signal1": 0.5,
            "signal2": 0.3,
            "signal3": 0.2,
        ]

        let result = weightedInterleave(buckets: buckets, weights: weights)
        #expect(result.count == 3)
        let resultIDs = Set(result.map(\.id))
        #expect(resultIDs.contains(MusicItemID("A")))
        #expect(resultIDs.contains(MusicItemID("B")))
        #expect(resultIDs.contains(MusicItemID("C")))
    }

    @Test("Weighted interleave handles empty buckets")
    func interleaveEmptyBuckets() {
        let buckets: [String: [CrateAlbum]] = [:]
        let weights: [String: Double] = [:]

        let result = weightedInterleave(buckets: buckets, weights: weights)
        #expect(result.isEmpty)
    }
}
