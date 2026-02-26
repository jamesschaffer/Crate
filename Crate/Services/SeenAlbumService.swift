import Foundation
import SwiftData

/// Tracks which albums have been shown in feeds across sessions.
///
/// Mirrors DislikeService pattern — all methods that touch the ModelContext
/// must be called from @MainActor.
final class SeenAlbumService {

    // MARK: - Model Context

    private(set) var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Decay Windows

    /// How many days to suppress recently-seen albums, based on dial position.
    private static func decayDays(for position: CrateDialPosition) -> Int {
        switch position {
        case .myCrate:      return 3
        case .curated:      return 5
        case .mixedCrate:   return 7
        case .deepDig:      return 10
        case .mysteryCrate: return 14
        }
    }

    // MARK: - CRUD

    /// Batch upsert: insert new records or update dateSeen for existing ones.
    @MainActor
    func markSeen(albumIDs: [String]) {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] SeenAlbumService.markSeen called before configure(modelContext:)")
            return
        }

        for id in albumIDs {
            let predicate = #Predicate<SeenAlbum> { $0.albumID == id }
            let descriptor = FetchDescriptor(predicate: predicate)

            do {
                let existing = try ctx.fetch(descriptor)
                if let record = existing.first {
                    record.dateSeen = .now
                } else {
                    ctx.insert(SeenAlbum(albumID: id))
                }
            } catch {
                #if DEBUG
                print("[Crate] SeenAlbumService.markSeen fetch failed for \(id): \(error)")
                #endif
            }
        }

        do {
            try ctx.save()
        } catch {
            #if DEBUG
            print("[Crate] SeenAlbumService.markSeen save failed: \(error)")
            #endif
        }
    }

    /// Fetch album IDs seen within the decay window for the given dial position.
    @MainActor
    func recentlySeenIDs(for position: CrateDialPosition) -> Set<String> {
        guard let ctx = modelContext else {
            assertionFailure("[Crate] SeenAlbumService.recentlySeenIDs called before configure(modelContext:)")
            return []
        }

        let days = Self.decayDays(for: position)
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now

        let predicate = #Predicate<SeenAlbum> { $0.dateSeen >= cutoff }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let records = try ctx.fetch(descriptor)
            return Set(records.map(\.albumID))
        } catch {
            #if DEBUG
            print("[Crate] SeenAlbumService.recentlySeenIDs failed: \(error)")
            #endif
            return []
        }
    }

    /// Delete records older than 14 days (the maximum decay window).
    @MainActor
    func purgeExpired() {
        guard let ctx = modelContext else { return }

        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
        let predicate = #Predicate<SeenAlbum> { $0.dateSeen < cutoff }
        let descriptor = FetchDescriptor(predicate: predicate)

        do {
            let expired = try ctx.fetch(descriptor)
            for record in expired {
                ctx.delete(record)
            }
            try ctx.save()
        } catch {
            #if DEBUG
            print("[Crate] SeenAlbumService.purgeExpired failed: \(error)")
            #endif
        }
    }
}
