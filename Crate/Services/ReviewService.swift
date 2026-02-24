import Foundation
import FirebaseFunctions
import SwiftData

/// Errors that can occur during review generation.
enum ReviewError: LocalizedError {
    case firebaseNotConfigured
    case invalidResponse
    case invalidJSON
    case rateLimited
    case appCheckFailed

    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase is not configured. Please restart the app."
        case .invalidResponse:
            return "Received an unexpected response from the review service."
        case .invalidJSON:
            return "Could not parse the review. Please try again."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .appCheckFailed:
            return "App verification failed. Please restart the app."
        }
    }
}

/// Generates AI album reviews via Firebase Cloud Functions and caches them in SwiftData.
///
/// All methods that touch the ModelContext must be called from @MainActor.
/// The service itself is not @MainActor so it can be stored as a property
/// in @Observable view models without isolation conflicts.
final class ReviewService {

    // MARK: - Dependencies

    var modelContext: ModelContext?
    private lazy var functions = Functions.functions()

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    // MARK: - Cache

    /// Fetch a cached review for the given album ID, or nil if not cached.
    @MainActor
    func cachedReview(albumID: String) -> AlbumReview? {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] ReviewService.cachedReview called before configure(modelContext:)")
            return nil
        }

        let predicate = #Predicate<AlbumReview> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let results = try ctx.fetch(descriptor)
            return results.first
        } catch {
            #if DEBUG
            print("[Crate] Failed to fetch cached review: \(error)")
            #endif
            return nil
        }
    }

    /// Save a review to SwiftData, replacing any existing review for the same album.
    @MainActor
    func saveReview(_ review: AlbumReview) {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] ReviewService.saveReview called before configure(modelContext:)")
            return
        }

        // Delete existing review for this album (upsert)
        let albumID = review.albumID
        let predicate = #Predicate<AlbumReview> { $0.albumID == albumID }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let existing = try ctx.fetch(descriptor)
            for old in existing {
                ctx.delete(old)
            }
        } catch {
            #if DEBUG
            print("[Crate] Failed to fetch existing reviews for upsert: \(error)")
            #endif
        }

        ctx.insert(review)
        do {
            try ctx.save()
        } catch {
            #if DEBUG
            print("[Crate] SwiftData save failed: \(error)")
            #endif
        }
    }

    // MARK: - Review Generation

    /// Generate a review for the given album via the Cloud Function.
    /// Record label is pre-fetched by AlbumDetailViewModel to avoid a redundant API call.
    /// The server owns the prompt template and search grounding decision.
    func generateReview(for album: CrateAlbum, recordLabel: String?) async throws -> AlbumReview {
        #if DEBUG
        print("[Crate] ========== REVIEW GENERATION START ==========")
        print("[Crate] Album: \(album.title) by \(album.artistName) (ID: \(album.id.rawValue))")
        #endif

        let label = recordLabel ?? "Unknown"

        let releaseYear: String
        if let date = album.releaseDate {
            releaseYear = String(Calendar.current.component(.year, from: date))
        } else {
            releaseYear = "Unknown"
        }

        let genres = album.genreNames.joined(separator: ", ")
        #if DEBUG
        print("[Crate] Metadata — year: \(releaseYear), genres: \(genres), label: \(label)")
        #endif

        return try await callCloudFunction(
            artistName: album.artistName,
            albumTitle: album.title,
            releaseYear: releaseYear,
            genres: genres,
            recordLabel: label,
            albumID: album.id.rawValue
        )
    }

    /// Call the Cloud Function and parse the response.
    private func callCloudFunction(
        artistName: String,
        albumTitle: String,
        releaseYear: String,
        genres: String,
        recordLabel: String,
        albumID: String
    ) async throws -> AlbumReview {
        let data: [String: Any] = [
            "artistName": artistName,
            "albumTitle": albumTitle,
            "releaseYear": releaseYear,
            "genres": genres,
            "recordLabel": recordLabel
        ]

        #if DEBUG
        print("[Crate] Calling generateReviewGemini (timeout: 120s)...")
        #endif
        let callStart = Date()
        let result: HTTPSCallableResult
        do {
            let callable = functions.httpsCallable("generateReviewGemini")
            callable.timeoutInterval = 120  // Match server-side timeout
            result = try await callable.call(data)
            let elapsed = Date().timeIntervalSince(callStart)
            #if DEBUG
            print("[Crate] Cloud Function returned in \(String(format: "%.1f", elapsed))s")
            #endif
        } catch let error as NSError {
            let elapsed = Date().timeIntervalSince(callStart)
            #if DEBUG
            print("[Crate] Cloud Function failed after \(String(format: "%.1f", elapsed))s")
            print("[Crate] Error — domain: \(error.domain), code: \(error.code), description: \(error.localizedDescription)")
            #endif
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                switch code {
                case .resourceExhausted:
                    throw ReviewError.rateLimited
                case .unauthenticated:
                    throw ReviewError.appCheckFailed
                default:
                    throw ReviewError.invalidResponse
                }
            }
            throw ReviewError.invalidResponse
        }

        // Parse response: data.data.choices[0].message.content → JSON string
        guard let resultData = result.data as? [String: Any],
              let success = resultData["success"] as? Bool,
              success,
              let openAIData = resultData["data"] as? [String: Any] else {
            #if DEBUG
            print("[Crate] FAILED at top-level parse (success/data extraction)")
            if let rawDict = result.data as? [String: Any] {
                print("[Crate] Top-level keys: \(Array(rawDict.keys))")
                if let errorMsg = rawDict["error"] { print("[Crate] error = \(errorMsg)") }
            }
            #endif
            throw ReviewError.invalidResponse
        }

        guard let choices = openAIData["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            #if DEBUG
            print("[Crate] FAILED at choices/message/content extraction")
            #endif
            throw ReviewError.invalidResponse
        }

        // Strip markdown code fences if present (Gemini sometimes wraps JSON)
        var cleanedText = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedText.hasPrefix("```") {
            if let firstNewline = cleanedText.firstIndex(of: "\n") {
                cleanedText = String(cleanedText[cleanedText.index(after: firstNewline)...])
            }
            if cleanedText.hasSuffix("```") {
                cleanedText = String(cleanedText.dropLast(3))
            }
            cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw ReviewError.invalidJSON
        }

        let parsed: ReviewResponse
        do {
            parsed = try JSONDecoder().decode(ReviewResponse.self, from: jsonData)
            #if DEBUG
            print("[Crate] Review parsed — rating: \(parsed.rating), recommendation: \(parsed.recommendation)")
            #endif
        } catch {
            #if DEBUG
            print("[Crate] JSON decode FAILED: \(error)")
            print("[Crate] Content: \(cleanedText.prefix(500))")
            #endif
            throw ReviewError.invalidJSON
        }

        #if DEBUG
        print("[Crate] ========== REVIEW GENERATION COMPLETE ==========")
        #endif
        return AlbumReview(
            albumID: albumID,
            contextSummary: parsed.contextSummary,
            contextBullets: parsed.contextBullets,
            rating: parsed.rating,
            recommendation: parsed.recommendation
        )
    }

}

// MARK: - Response Decoding

/// Decoded response from the Gemini review Cloud Function.
private struct ReviewResponse: Codable {
    let contextSummary: String
    let contextBullets: [String]
    let rating: Double
    let recommendation: String
    let keyTracks: [String]?  // Required by Cloud Function validation but unused in UI

    enum CodingKeys: String, CodingKey {
        case contextSummary = "context_summary"
        case contextBullets = "context_bullets"
        case rating
        case recommendation
        case keyTracks = "key_tracks"
    }
}
