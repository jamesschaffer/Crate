import Foundation
import Observation
import SwiftData

/// Manages state for the album review tab in AlbumDetailView.
@MainActor
@Observable
final class AlbumReviewViewModel {

    // MARK: - Dependencies

    private let reviewService: ReviewService

    // MARK: - State

    /// The cached or freshly generated review.
    var review: AlbumReview?

    /// True while generating a review for the first time.
    var isGenerating: Bool = false

    /// True while regenerating (replacing an existing review).
    var isRegenerating: Bool = false

    /// Error message to display if generation fails.
    var errorMessage: String?

    // MARK: - Init

    init(reviewService: ReviewService = ReviewService()) {
        self.reviewService = reviewService
    }

    // MARK: - Configuration

    /// Inject the SwiftData model context. Call from the view layer before any operations.
    func configure(modelContext: ModelContext) {
        reviewService.modelContext = modelContext
    }

    // MARK: - Actions

    /// Check SwiftData for a cached review on appear.
    func loadCachedReview(albumID: String) {
        review = reviewService.cachedReview(albumID: albumID)
    }

    /// Generate a new review via the Cloud Function and cache it.
    func generateReview(for album: CrateAlbum, recordLabel: String?) async {
        let isRegenerate = review != nil
        if isRegenerate {
            isRegenerating = true
        } else {
            isGenerating = true
        }
        errorMessage = nil

        do {
            let newReview = try await reviewService.generateReview(for: album, recordLabel: recordLabel)
            reviewService.saveReview(newReview)
            review = newReview
            #if DEBUG
            print("[Crate] Review saved to cache for album: \(album.id.rawValue)")
            #endif
        } catch {
            #if DEBUG
            print("[Crate] Review generation failed — type: \(type(of: error)), error: \(error)")
            #endif
            if let reviewError = error as? ReviewError {
                #if DEBUG
                print("[Crate] ReviewError case: \(reviewError)")
                #endif
                errorMessage = reviewError.errorDescription
            } else {
                #if DEBUG
                print("[Crate] Non-ReviewError: \(error.localizedDescription)")
                #endif
                errorMessage = "Something went wrong. Please try again."
            }
        }

        isGenerating = false
        isRegenerating = false
    }
}
