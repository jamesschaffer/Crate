import Foundation
import Testing
import SwiftData
#if os(macOS)
@testable import Crate_macOS
#else
@testable import Crate_iOS
#endif

/// Tests for SeenAlbumService CRUD operations and decay windows.
///
/// Uses an in-memory SwiftData ModelContainer so tests don't touch disk.
struct SeenAlbumServiceTests {

    /// Create an in-memory container with all required models.
    private func makeContext() throws -> ModelContext {
        let schema = Schema([FavoriteAlbum.self, DislikedAlbum.self, SeenAlbum.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    @Test("SeenAlbum model initializes correctly")
    func modelInit() {
        let seen = SeenAlbum(albumID: "12345")
        #expect(seen.albumID == "12345")
        #expect(seen.dateSeen <= Date.now)
    }

    @Test("markSeen inserts new records")
    @MainActor
    func markSeenInsertsNew() throws {
        let ctx = try makeContext()
        let service = SeenAlbumService(modelContext: ctx)

        service.markSeen(albumIDs: ["A", "B", "C"])

        let ids = service.recentlySeenIDs(for: .mysteryCrate) // 14-day window
        #expect(ids.count == 3)
        #expect(ids.contains("A"))
        #expect(ids.contains("B"))
        #expect(ids.contains("C"))
    }

    @Test("markSeen updates existing records instead of duplicating")
    @MainActor
    func markSeenUpdatesExisting() throws {
        let ctx = try makeContext()
        let service = SeenAlbumService(modelContext: ctx)

        service.markSeen(albumIDs: ["DUP"])
        service.markSeen(albumIDs: ["DUP"])

        let descriptor = FetchDescriptor<SeenAlbum>()
        let all = try ctx.fetch(descriptor)
        #expect(all.count == 1)
    }

    @Test("recentlySeenIDs respects decay window for My Crate (3 days)")
    @MainActor
    func decayWindowMyCrate() throws {
        let ctx = try makeContext()
        let service = SeenAlbumService(modelContext: ctx)

        // Insert a record dated 4 days ago (outside My Crate's 3-day window).
        let old = SeenAlbum(albumID: "OLD", dateSeen: Date.now.addingTimeInterval(-4 * 86400))
        ctx.insert(old)
        try ctx.save()

        // Insert a recent record.
        service.markSeen(albumIDs: ["NEW"])

        let ids = service.recentlySeenIDs(for: .myCrate)
        #expect(!ids.contains("OLD"), "4-day-old record should be outside My Crate's 3-day window")
        #expect(ids.contains("NEW"))
    }

    @Test("recentlySeenIDs returns old records for Mystery Crate (14 days)")
    @MainActor
    func decayWindowMysteryCrate() throws {
        let ctx = try makeContext()
        let service = SeenAlbumService(modelContext: ctx)

        // Insert a record dated 10 days ago (inside Mystery Crate's 14-day window).
        let old = SeenAlbum(albumID: "OLD10", dateSeen: Date.now.addingTimeInterval(-10 * 86400))
        ctx.insert(old)
        try ctx.save()

        let ids = service.recentlySeenIDs(for: .mysteryCrate)
        #expect(ids.contains("OLD10"), "10-day-old record should be inside Mystery Crate's 14-day window")
    }

    @Test("purgeExpired deletes records older than 14 days")
    @MainActor
    func purgeExpired() throws {
        let ctx = try makeContext()
        let service = SeenAlbumService(modelContext: ctx)

        // Insert a record dated 15 days ago.
        let expired = SeenAlbum(albumID: "EXPIRED", dateSeen: Date.now.addingTimeInterval(-15 * 86400))
        ctx.insert(expired)

        // Insert a recent record.
        let recent = SeenAlbum(albumID: "RECENT")
        ctx.insert(recent)
        try ctx.save()

        service.purgeExpired()

        let descriptor = FetchDescriptor<SeenAlbum>()
        let remaining = try ctx.fetch(descriptor)
        #expect(remaining.count == 1)
        #expect(remaining.first?.albumID == "RECENT")
    }

    @Test("Empty state returns empty set")
    @MainActor
    func emptyState() throws {
        let ctx = try makeContext()
        let service = SeenAlbumService(modelContext: ctx)

        let ids = service.recentlySeenIDs(for: .mixedCrate)
        #expect(ids.isEmpty)
    }
}
