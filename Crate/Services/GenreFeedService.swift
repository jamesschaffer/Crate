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

            // Trending: chart albums for this genre with dial-scaled random offset
            if trendingCount > 0 {
                let trendingLimit = Int(Double(trendingCount + 5) * OffsetStrategy.overFetchMultiplier)
                group.addTask {
                    let offset = OffsetStrategy.randomChartOffset(for: position)
                    let albums = await self.fetchChartsSafe(genreID: self.genre.appleMusicID, limit: trendingLimit, offset: offset)
                    return (.trending, self.filterToGenre(albums))
                }
            }

            // New Releases: new release charts for this genre
            if newRelCount > 0 {
                let newRelLimit = Int(Double(newRelCount + 5) * OffsetStrategy.overFetchMultiplier)
                group.addTask {
                    let offset = OffsetStrategy.randomNewReleaseOffset(for: position)
                    let albums = await self.fetchNewReleasesSafe(genreID: self.genre.appleMusicID, limit: newRelLimit, offset: offset)
                    return (.newReleases, self.filterToGenre(albums))
                }
            }

            // Subcategory Rotation: pick random subcategories and fetch their charts
            if subcatCount > 0 {
                let subcats = Array(genre.subcategories.shuffled().prefix(3))
                let perSubcat = Int(Double(max(subcatCount / max(subcats.count, 1), 5)) * OffsetStrategy.overFetchMultiplier)
                for subcat in subcats {
                    group.addTask {
                        let offset = OffsetStrategy.randomChartOffset(for: position)
                        let albums = await self.fetchChartsSafe(genreID: subcat.appleMusicID, limit: perSubcat, offset: offset)
                        return (.subcategoryRotation, self.filterToGenre(albums))
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
                        do {
                            let related = try await self.musicService.fetchRelatedAlbums(for: MusicItemID(seed.albumID))
                            albums.append(contentsOf: related)
                        } catch {
                            #if DEBUG
                            print("[Crate] GenreFeed fetchRelatedAlbums failed for \(seed.albumID): \(error)")
                            #endif
                        }
                        // Fetch artist's other albums
                        do {
                            let artistAlbums = try await self.musicService.fetchAlbumsByArtist(name: seed.artistName, limit: 10)
                            albums.append(contentsOf: artistAlbums)
                        } catch {
                            #if DEBUG
                            print("[Crate] GenreFeed fetchAlbumsByArtist failed for \(seed.artistName): \(error)")
                            #endif
                        }
                        return (.seedExpansion, self.filterToGenre(albums))
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
        return WeightedInterleave.interleave(buckets: buckets, weights: weightValues)
    }

    // MARK: - Signal Fetchers

    /// Fetch heavy rotation + library albums filtered to this genre.
    private func fetchPersonalHistory(limit: Int) async -> [CrateAlbum] {
        var albums: [CrateAlbum] = []

        // Heavy rotation
        do {
            let heavy = try await musicService.fetchHeavyRotation(limit: 25)
            albums.append(contentsOf: filterToGenre(heavy))
        } catch {
            #if DEBUG
            print("[Crate] GenreFeed fetchHeavyRotation failed: \(error)")
            #endif
        }

        // Library albums (randomized offset for variability)
        let libraryOffset = OffsetStrategy.randomLibraryOffset(for: dialStore.position)
        do {
            let library = try await musicService.fetchLibraryAlbums(limit: 25, offset: libraryOffset)
            albums.append(contentsOf: filterToGenre(library))
        } catch {
            #if DEBUG
            print("[Crate] GenreFeed fetchLibraryAlbums failed: \(error)")
            #endif
        }

        // If sparse, also pull recently played
        if albums.count < limit / 2 {
            do {
                let recent = try await musicService.fetchRecentlyPlayed(limit: 25)
                albums.append(contentsOf: filterToGenre(recent))
            } catch {
                #if DEBUG
                print("[Crate] GenreFeed fetchRecentlyPlayed failed: \(error)")
                #endif
            }
        }

        return albums
    }

    /// Fetch recommendations filtered to this genre.
    private func fetchRecommendationsForGenre(limit: Int) async -> [CrateAlbum] {
        do {
            let recs = try await musicService.fetchRecommendations(limit: limit)
            return filterToGenre(recs)
        } catch {
            #if DEBUG
            print("[Crate] GenreFeed fetchRecommendations failed: \(error)")
            #endif
            return []
        }
    }

    /// Filter albums to those matching this genre or its subcategories.
    private func filterToGenre(_ albums: [CrateAlbum]) -> [CrateAlbum] {
        genre.filterAlbums(albums)
    }

    // MARK: - Safe Fetch Wrappers

    private func fetchChartsSafe(genreID: String, limit: Int, offset: Int) async -> [CrateAlbum] {
        do {
            return try await musicService.fetchChartAlbums(genreID: genreID, limit: limit, offset: offset)
        } catch {
            #if DEBUG
            print("[Crate] GenreFeed fetchChartAlbums failed: \(error)")
            #endif
            return []
        }
    }

    private func fetchNewReleasesSafe(genreID: String, limit: Int, offset: Int = 0) async -> [CrateAlbum] {
        do {
            return try await musicService.fetchNewReleaseChartAlbums(genreID: genreID, limit: limit, offset: offset)
        } catch {
            #if DEBUG
            print("[Crate] GenreFeed fetchNewReleaseChartAlbums failed: \(error)")
            #endif
            return []
        }
    }
}
