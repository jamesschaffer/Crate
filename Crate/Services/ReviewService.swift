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

    /// Gemini's training data cutoff. Albums released before this date
    /// can skip Google Search grounding for faster responses.
    private static let searchCutoffDate: Date = {
        DateComponents(calendar: .current, year: 2024, month: 7, day: 1).date!
    }()

    /// Generate a review for the given album via the Cloud Function.
    /// Record label is pre-fetched by AlbumDetailViewModel to avoid a redundant API call.
    /// If search grounding causes a truncation error, retries without search.
    func generateReview(for album: CrateAlbum, recordLabel: String?) async throws -> AlbumReview {
        #if DEBUG
        print("[Crate] ========== REVIEW GENERATION START ==========")
        print("[Crate] Album: \(album.title) by \(album.artistName) (ID: \(album.id.rawValue))")
        #endif

        let label = recordLabel ?? "Unknown"

        // Build release year from date
        let releaseYear: String
        if let date = album.releaseDate {
            releaseYear = String(Calendar.current.component(.year, from: date))
        } else {
            releaseYear = "Unknown"
        }

        // Enable search grounding only for albums released after Gemini's training cutoff
        let useSearch: Bool
        if let releaseDate = album.releaseDate {
            useSearch = releaseDate >= Self.searchCutoffDate
        } else {
            useSearch = true  // Unknown date → use search to be safe
        }

        let genres = album.genreNames.joined(separator: ", ")
        #if DEBUG
        print("[Crate] Metadata — year: \(releaseYear), genres: \(genres), label: \(label)")
        #endif

        let prompt = Self.buildPrompt(
            artistName: album.artistName,
            albumTitle: album.title,
            releaseYear: releaseYear,
            genres: genres,
            recordLabel: label
        )
        #if DEBUG
        print("[Crate] Prompt built (\(prompt.count) chars)")
        #endif

        // Try with search first; if it fails (truncation from token limits),
        // retry without search as a fallback.
        if useSearch {
            #if DEBUG
            print("[Crate] Search grounding: ON (post-cutoff)")
            #endif
            do {
                return try await callCloudFunction(prompt: prompt, useSearch: true, albumID: album.id.rawValue)
            } catch {
                #if DEBUG
                print("[Crate] Search attempt failed — retrying without search grounding")
                #endif
            }
        }

        #if DEBUG
        print("[Crate] Search grounding: OFF")
        #endif
        return try await callCloudFunction(prompt: prompt, useSearch: false, albumID: album.id.rawValue)
    }

    /// Call the Cloud Function and parse the response.
    private func callCloudFunction(prompt: String, useSearch: Bool, albumID: String) async throws -> AlbumReview {
        let data: [String: Any] = [
            "prompt": prompt,
            "useSearch": useSearch
        ]

        #if DEBUG
        print("[Crate] Calling generateReviewGemini (useSearch: \(useSearch), timeout: 120s)...")
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

    // MARK: - Prompt

    static func buildPrompt(
        artistName: String,
        albumTitle: String,
        releaseYear: String,
        genres: String,
        recordLabel: String
    ) -> String {
        reviewPromptTemplate
            .replacingOccurrences(of: "{artistName}", with: artistName)
            .replacingOccurrences(of: "{albumTitle}", with: albumTitle)
            .replacingOccurrences(of: "{releaseYear}", with: releaseYear)
            .replacingOccurrences(of: "{genres}", with: genres)
            .replacingOccurrences(of: "{recordLabel}", with: recordLabel)
    }

    // MARK: - Prompt Template

    // swiftlint:disable line_length
    private static let reviewPromptTemplate = """
    You are a music critic writing an honest, evidence-based album review for collectors who care about artistic merit, not financial value.

    **Album Metadata:**
    Artist: {artistName}
    Album: {albumTitle}
    Year: {releaseYear}
    Genre: {genres}
    Label: {recordLabel}

    **Your Task:**
    Generate a concise, honest assessment of this album's cultural significance and musical merit based on your knowledge of music history, critical reception, influence, and cultural impact.

    **Source Prioritization:**
    When searching for evidence and critical reception, prioritize these sources (in order):
    - Metacritic
    - Album of the Year
    - Pitchfork
    - Rolling Stone
    - AllMusic
    - The Guardian

    **Source Diversity Rules:**
    To ensure comprehensive and credible reviews, follow these citation rules:
    - Use NO MORE than 2 URLs from any single domain (e.g., max 2 Wikipedia links)
    - Aim to cite at least 3 different sources from the priority list
    - Prefer Metacritic/Pitchfork for review scores and critical consensus
    - Use Wikipedia for general context, background, and album basics
    - Use music publications (Rolling Stone, AllMusic) for in-depth analysis and cultural impact
    - Diversify your sources to provide multiple perspectives

    **Required Output Structure:**

    1. **context_summary** (2-3 sentences): Opening paragraph that captures the album's core essence and importance. Be specific about what makes it matter (or not).

    2. **context_bullets** (3-5 bullet points): Concrete evidence supporting your assessment:
       - Critical reception (scores from Pitchfork, Rolling Stone, Metacritic when available)
       - Concrete impact examples (chart performance, sales figures, awards)
       - Specific standout tracks and sonic qualities
       - Genre innovation or influence on other artists
       - Reputation evolution (initially panned vs. later acclaimed, etc.)

    3. **rating** (number 0-10): Your assessment based on the album's artistic merit and cultural significance.

    4. **recommendation** (string): Choose ONE label that best captures this album's place in music:

       TIER 1 (Undeniable Greatness): Essential Classic | Genre Landmark | Cultural Monument
       TIER 2 (Critical Darlings): Indie Masterpiece | Cult Essential | Critics' Choice
       TIER 3 (Crowd Pleasers): Crowd Favorite | Radio Gold | Crossover Success
       TIER 4 (Hidden Gems): Deep Cut | Surprise Excellence | Scene Favorite
       TIER 5 (Historical Interest): Time Capsule | Influential Curio | Pioneering Effort
       TIER 6 (Solid Work): Reliable Listen | Fan Essential | Genre Staple
       TIER 7 (Problematic): Ambitious Failure | Divisive Work | Uneven Effort
       TIER 8 (Pass): Forgettable Entry | Career Low | Avoid Entirely

    **Critical Requirements:**
    - Use honest, direct language - call out mediocre or bad albums explicitly
    - Focus on what actually matters about the album (no filler or generic praise)
    - Evaluate albums purely on musical merit - artist's personal controversies or social issues may be mentioned for context but do NOT devalue their musical contributions or impact
    - Provide specific evidence (scores, chart positions, awards, influence examples)
    - Choose the recommendation carefully based on the album's actual place in music history, not just your personal opinion
    - Reserve Tier 1 labels for genuinely canonical/influential albums only
    - NEVER mention price, monetary value, market considerations, investment potential, pressing details, or collectibility
    - Be the honest music historian, not the investment advisor

    Return ONLY valid JSON in this exact format:
    {
      "context_summary": "string",
      "context_bullets": ["string", "string", "string"],
      "rating": number,
      "recommendation": "string (exactly as written above)",
      "key_tracks": ["string", "string", "string"]
    }
    """
    // swiftlint:enable line_length
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
