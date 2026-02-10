import Foundation
import MusicKit

/// Lightweight seed data extracted from FavoriteAlbum for Sendable compatibility.
struct SeedAlbum: Sendable {
    let albumID: String
    let artistName: String
}

/// Builds multi-signal genre feeds using the same parallel-fetch + weighted-interleave
/// pattern as CrateWallService, but scoped to a specific genre with 6 signal sources.
struct GenreFeedService: Sendable {

    private let genre: GenreCategory
    private let musicService: MusicServiceProtocol
    private let dialStore: CrateDialStore
    /// IDs of disliked albums to exclude from all results.
    private let excludedAlbumIDs: Set<String>
    /// Favorited albums used as seeds for expansion.
    private let seedAlbums: [SeedAlbum]

    init(genre: GenreCategory,
         musicService: MusicServiceProtocol = MusicService(),
         dialStore: CrateDialStore = CrateDialStore(),
         excludedAlbumIDs: Set<String> = [],
         seedAlbums: [FavoriteAlbum] = []) {
        self.genre = genre
        self.musicService = musicService
        self.dialStore = dialStore
        self.excludedAlbumIDs = excludedAlbumIDs
        self.seedAlbums = seedAlbums.map { SeedAlbum(albumID: $0.albumID, artistName: $0.artistName) }
    }

    // MARK: - Public

    /// Generate a batch of genre-filtered albums from multiple signals.
    func generateFeed(total: Int, excluding: Set<MusicItemID>) async -> [CrateAlbum] {
        let position = dialStore.position
        let feedWeights = GenreFeedWeights.weights(for: position)
        var counts = feedWeights.albumCounts(total: total)

        // Step 1: Parallel fetch all signal sources.
        var buckets: [GenreFeedSignal: [CrateAlbum]] = [:]

        await withTaskGroup(of: (GenreFeedSignal, [CrateAlbum]).self) { group in
            let historyCount = counts[.personalHistory, default: 0]
            let recsCount = counts[.recommendations, default: 0]
            let trendingCount = counts[.trending, default: 0]
            let newRelCount = counts[.newReleases, default: 0]
            let subcatCount = counts[.subcategoryRotation, default: 0]
            let seedCount = counts[.seedExpansion, default: 0]

            // Personal History: heavy rotation + library albums filtered to this genre
            if historyCount > 0 {
                group.addTask {
                    let albums = await self.fetchPersonalHistory(limit: historyCount + 10)
                    return (.personalHistory, albums)
                }
            }

            // Recommendations: filtered to this genre
            if recsCount > 0 {
                group.addTask {
                    let albums = await self.fetchRecommendationsForGenre(limit: recsCount + 10)
                    return (.recommendations, albums)
                }
            }

            // Trending: chart albums for this genre with random offset
            if trendingCount > 0 {
                group.addTask {
                    let offset = Int.random(in: 0...50)
                    let albums = await self.fetchChartsSafe(genreID: self.genre.appleMusicID, limit: trendingCount + 5, offset: offset)
                    return (.trending, albums)
                }
            }

            // New Releases: new release charts for this genre
            if newRelCount > 0 {
                group.addTask {
                    let albums = await self.fetchNewReleasesSafe(genreID: self.genre.appleMusicID, limit: newRelCount + 5)
                    return (.newReleases, albums)
                }
            }

            // Subcategory Rotation: pick random subcategories and fetch their charts
            if subcatCount > 0 {
                let subcats = Array(genre.subcategories.shuffled().prefix(3))
                let perSubcat = max(subcatCount / max(subcats.count, 1), 5)
                for subcat in subcats {
                    group.addTask {
                        let albums = await self.fetchChartsSafe(genreID: subcat.appleMusicID, limit: perSubcat, offset: 0)
                        return (.subcategoryRotation, albums)
                    }
                }
            }

            // Seed Expansion: related albums + artist albums from favorited seeds
            if seedCount > 0, !seedAlbums.isEmpty {
                let seeds = Array(seedAlbums.shuffled().prefix(3))
                for seed in seeds {
                    group.addTask {
                        var albums: [CrateAlbum] = []
                        // Fetch related albums
                        if let related = try? await self.musicService.fetchRelatedAlbums(for: MusicItemID(seed.albumID)) {
                            albums.append(contentsOf: related)
                        }
                        // Fetch artist's other albums
                        if let artistAlbums = try? await self.musicService.fetchAlbumsByArtist(name: seed.artistName, limit: 10) {
                            albums.append(contentsOf: artistAlbums)
                        }
                        return (.seedExpansion, albums)
                    }
                }
            }

            for await (signal, albums) in group {
                buckets[signal, default: []].append(contentsOf: albums)
            }
        }

        // If no seeds, redistribute seed expansion count to other signals.
        if seedAlbums.isEmpty {
            let seedCount = counts[.seedExpansion, default: 0]
            counts[.seedExpansion] = 0
            counts[.subcategoryRotation, default: 0] += seedCount / 2
            counts[.trending, default: 0] += seedCount - (seedCount / 2)
        }

        // Step 2: Deduplicate across all buckets + filter disliked albums.
        let dislikedMusicIDs = Set(excludedAlbumIDs.map { MusicItemID($0) })
        var seenIDs = excluding.union(dislikedMusicIDs)
        for signal in GenreFeedSignal.allCases {
            buckets[signal] = (buckets[signal] ?? []).filter { album in
                guard !seenIDs.contains(album.id) else { return false }
                seenIDs.insert(album.id)
                return true
            }
        }

        // Trim each bucket to its target count.
        for signal in GenreFeedSignal.allCases {
            let target = counts[signal, default: 0]
            if let bucket = buckets[signal], bucket.count > target {
                buckets[signal] = Array(bucket.shuffled().prefix(target))
            }
        }

        // Step 3: Weighted interleave.
        let weightValues = feedWeights.values
        return weightedInterleave(buckets: buckets, weights: weightValues)
    }

    // MARK: - Signal Fetchers

    /// Fetch heavy rotation + library albums filtered to this genre.
    private func fetchPersonalHistory(limit: Int) async -> [CrateAlbum] {
        var albums: [CrateAlbum] = []

        // Heavy rotation
        if let heavy = try? await musicService.fetchHeavyRotation(limit: 25) {
            albums.append(contentsOf: filterToGenre(heavy))
        }

        // Library albums
        if let library = try? await musicService.fetchLibraryAlbums(limit: 25, offset: 0) {
            albums.append(contentsOf: filterToGenre(library))
        }

        // If sparse, also pull recently played
        if albums.count < limit / 2 {
            if let recent = try? await musicService.fetchRecentlyPlayed(limit: 25) {
                albums.append(contentsOf: filterToGenre(recent))
            }
        }

        return albums
    }

    /// Fetch recommendations filtered to this genre.
    private func fetchRecommendationsForGenre(limit: Int) async -> [CrateAlbum] {
        guard let recs = try? await musicService.fetchRecommendations(limit: limit) else {
            return []
        }
        return filterToGenre(recs)
    }

    /// Filter albums to those matching this genre or its subcategories.
    private func filterToGenre(_ albums: [CrateAlbum]) -> [CrateAlbum] {
        let genreNameSet = Set([genre.name.lowercased()] + genre.subcategories.map { $0.name.lowercased() })
        return albums.filter { album in
            album.genreNames.contains { name in
                genreNameSet.contains(name.lowercased()) ||
                name.localizedCaseInsensitiveContains(genre.name)
            }
        }
    }

    // MARK: - Safe Fetch Wrappers

    private func fetchChartsSafe(genreID: String, limit: Int, offset: Int) async -> [CrateAlbum] {
        (try? await musicService.fetchChartAlbums(genreID: genreID, limit: limit, offset: offset)) ?? []
    }

    private func fetchNewReleasesSafe(genreID: String, limit: Int) async -> [CrateAlbum] {
        (try? await musicService.fetchNewReleaseChartAlbums(genreID: genreID, limit: limit, offset: 0)) ?? []
    }
}
