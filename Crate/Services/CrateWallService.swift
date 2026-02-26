import Foundation
import MusicKit

/// Orchestrates the five signal sources into a shuffled wall of albums.
///
/// Algorithm summary:
/// 1. Read Crate Dial → compute per-signal album counts
/// 2. Fetch recently played → extract genre IDs for personalized chart lookups
/// 3. Fire parallel fetches via TaskGroup
/// 4. Deduplicate across signals
/// 5. Weighted-interleave so higher-weighted signals appear more often but aren't clustered
struct CrateWallService: Sendable {

    private let musicService: MusicServiceProtocol
    private let dialStore: CrateDialStore
    /// Album IDs to exclude from all wall results (disliked albums).
    private let excludedAlbumIDs: Set<String>

    init(musicService: MusicServiceProtocol = MusicService(),
         dialStore: CrateDialStore = CrateDialStore(),
         excludedAlbumIDs: Set<String> = []) {
        self.musicService = musicService
        self.dialStore = dialStore
        self.excludedAlbumIDs = excludedAlbumIDs
    }

    // MARK: - Public

    /// Generate the initial wall (~100 albums).
    func generateWall(excluding seenIDs: Set<MusicItemID> = []) async -> [CrateAlbum] {
        await buildWall(total: 100, excluding: seenIDs)
    }

    /// Fetch more albums for infinite scroll (~50), excluding already-displayed IDs.
    func fetchMore(excluding existingIDs: Set<MusicItemID>) async -> [CrateAlbum] {
        await buildWall(total: 50, excluding: existingIDs)
    }

    // MARK: - Core Algorithm

    private func buildWall(total: Int, excluding: Set<MusicItemID>) async -> [CrateAlbum] {
        let position = dialStore.position
        let weights = CrateDialWeights.weights(for: position)
        var counts = weights.albumCounts(total: total)

        // Step 1: Fetch recently played + heavy rotation + library for genre preferences.
        let libraryOffset = OffsetStrategy.randomLibraryOffset(for: position)
        async let recentTask = fetchRecentlyPlayedSafe()
        async let heavyTask = fetchHeavyRotationSafe()
        async let libraryTask = fetchLibraryAlbumsSafe(offset: libraryOffset)

        let recentlyPlayed = await recentTask
        let heavyRotation = await heavyTask
        let libraryAlbums = await libraryTask
        let allPersonalAlbums = recentlyPlayed + heavyRotation + libraryAlbums
        let userGenreIDs = extractGenreIDs(from: allPersonalAlbums)

        // If too few personal history items, redistribute Listening History count.
        if allPersonalAlbums.count < 15 {
            let historyCount = counts[.listeningHistory, default: 0]
            counts[.listeningHistory] = 0
            counts[.recommendations, default: 0] += historyCount
        }

        // Step 2: Pick random genres for each signal bucket.
        let allGenres = Genres.all
        let userGenres = allGenres.filter { userGenreIDs.contains($0.appleMusicID) }
        let historyGenres = userGenres.isEmpty ? Array(allGenres.shuffled().prefix(2)) : Array(userGenres.shuffled().prefix(3))
        let chartGenres = Array(allGenres.shuffled().prefix(3))
        let newReleaseGenres = Array(allGenres.shuffled().prefix(2))

        // Wild card genres: avoid overlap with other picks.
        let usedGenreIDs = Set(historyGenres.map(\.id) + chartGenres.map(\.id) + newReleaseGenres.map(\.id))
        let wildCardPool = allGenres.filter { !usedGenreIDs.contains($0.id) }
        let wildCardGenres = wildCardPool.isEmpty
            ? Array(allGenres.shuffled().prefix(2))
            : Array(wildCardPool.shuffled().prefix(2))

        // Step 3: Parallel fetches via TaskGroup.
        var buckets: [WallSignal: [CrateAlbum]] = [:]

        await withTaskGroup(of: (WallSignal, [CrateAlbum]).self) { group in
            let historyCount = counts[.listeningHistory, default: 0]
            let recsCount = counts[.recommendations, default: 0]
            let chartsCount = counts[.popularCharts, default: 0]
            let newRelCount = counts[.newReleases, default: 0]
            let wildCount = counts[.wildCard, default: 0]

            // Listening History: chart albums in user's genres
            if historyCount > 0 {
                let perGenre = Int(Double(max(historyCount / max(historyGenres.count, 1), 5)) * OffsetStrategy.overFetchMultiplier)
                for genre in historyGenres {
                    group.addTask {
                        let offset = OffsetStrategy.randomChartOffset(for: position)
                        let albums = await self.fetchChartsSafe(genreID: genre.appleMusicID, limit: perGenre, offset: offset)
                        return (.listeningHistory, albums)
                    }
                }
            }

            // Recommendations
            if recsCount > 0 {
                group.addTask {
                    let albums = await self.fetchRecommendationsSafe(limit: recsCount)
                    return (.recommendations, albums)
                }
            }

            // Popular Charts
            if chartsCount > 0 {
                let perGenre = Int(Double(max(chartsCount / max(chartGenres.count, 1), 5)) * OffsetStrategy.overFetchMultiplier)
                for genre in chartGenres {
                    group.addTask {
                        let offset = OffsetStrategy.randomChartOffset(for: position)
                        let albums = await self.fetchChartsSafe(genreID: genre.appleMusicID, limit: perGenre, offset: offset)
                        return (.popularCharts, albums)
                    }
                }
            }

            // New Releases
            if newRelCount > 0 {
                let perGenre = Int(Double(max(newRelCount / max(newReleaseGenres.count, 1), 5)) * OffsetStrategy.overFetchMultiplier)
                for genre in newReleaseGenres {
                    group.addTask {
                        let offset = OffsetStrategy.randomNewReleaseOffset(for: position)
                        let albums = await self.fetchNewReleasesSafe(genreID: genre.appleMusicID, limit: perGenre, offset: offset)
                        return (.newReleases, albums)
                    }
                }
            }

            // Wild Card
            if wildCount > 0 {
                let perGenre = Int(Double(max(wildCount / max(wildCardGenres.count, 1), 5)) * OffsetStrategy.overFetchMultiplier)
                for genre in wildCardGenres {
                    group.addTask {
                        let offset = OffsetStrategy.randomChartOffset(for: position)
                        let albums = await self.fetchChartsSafe(genreID: genre.appleMusicID, limit: perGenre, offset: offset)
                        return (.wildCard, albums)
                    }
                }
            }

            for await (signal, albums) in group {
                buckets[signal, default: []].append(contentsOf: albums)
            }
        }

        // Step 4: Deduplicate across all buckets + filter disliked albums.
        let dislikedMusicIDs = Set(excludedAlbumIDs.map { MusicItemID($0) })
        var seenIDs = excluding.union(dislikedMusicIDs)
        for signal in WallSignal.allCases {
            buckets[signal] = (buckets[signal] ?? []).filter { album in
                guard !seenIDs.contains(album.id) else { return false }
                seenIDs.insert(album.id)
                return true
            }
        }

        // Trim each bucket to its target count.
        for signal in WallSignal.allCases {
            let target = counts[signal, default: 0]
            if let bucket = buckets[signal], bucket.count > target {
                buckets[signal] = Array(bucket.shuffled().prefix(target))
            }
        }

        // Step 5: Weighted interleave using shared utility.
        return WeightedInterleave.interleave(buckets: buckets, weights: weights.values)
    }

    // MARK: - Genre Extraction

    /// Match genre names from recently played albums to our static genre taxonomy IDs.
    private func extractGenreIDs(from albums: [CrateAlbum]) -> Set<String> {
        // Pre-lowercase all genre names once to avoid repeated locale-aware comparisons.
        let lowercasedNames = albums.flatMap(\.genreNames).map { $0.lowercased() }
        var ids: Set<String> = []

        for category in Genres.all {
            let categoryLower = category.name.lowercased()

            // Check top-level genre name match.
            if lowercasedNames.contains(where: { $0.contains(categoryLower) }) {
                ids.insert(category.appleMusicID)
                continue  // Already matched — skip subcategory checks
            }

            // Check subcategory name matches.
            for sub in category.subcategories {
                let subLower = sub.name.lowercased()
                if lowercasedNames.contains(where: { $0.contains(subLower) }) {
                    ids.insert(category.appleMusicID)
                    break  // Found match — skip remaining subcategories
                }
            }
        }

        return ids
    }

    // MARK: - Safe Fetch Wrappers (graceful degradation)

    private func fetchRecentlyPlayedSafe() async -> [CrateAlbum] {
        do {
            return try await musicService.fetchRecentlyPlayed(limit: 25)
        } catch {
            #if DEBUG
            print("[Crate] fetchRecentlyPlayed failed: \(error)")
            #endif
            return []
        }
    }

    private func fetchHeavyRotationSafe() async -> [CrateAlbum] {
        do {
            return try await musicService.fetchHeavyRotation(limit: 25)
        } catch {
            #if DEBUG
            print("[Crate] fetchHeavyRotation failed: \(error)")
            #endif
            return []
        }
    }

    private func fetchLibraryAlbumsSafe(offset: Int = 0) async -> [CrateAlbum] {
        do {
            return try await musicService.fetchLibraryAlbums(limit: 25, offset: offset)
        } catch {
            #if DEBUG
            print("[Crate] fetchLibraryAlbums failed: \(error)")
            #endif
            return []
        }
    }

    private func fetchRecommendationsSafe(limit: Int) async -> [CrateAlbum] {
        do {
            return try await musicService.fetchRecommendations(limit: limit)
        } catch {
            #if DEBUG
            print("[Crate] fetchRecommendations failed: \(error)")
            #endif
            return []
        }
    }

    private func fetchChartsSafe(genreID: String, limit: Int, offset: Int) async -> [CrateAlbum] {
        do {
            return try await musicService.fetchChartAlbums(genreID: genreID, limit: limit, offset: offset)
        } catch {
            #if DEBUG
            print("[Crate] fetchChartAlbums failed: \(error)")
            #endif
            return []
        }
    }

    private func fetchNewReleasesSafe(genreID: String, limit: Int, offset: Int) async -> [CrateAlbum] {
        do {
            return try await musicService.fetchNewReleaseChartAlbums(genreID: genreID, limit: limit, offset: offset)
        } catch {
            #if DEBUG
            print("[Crate] fetchNewReleaseChartAlbums failed: \(error)")
            #endif
            return []
        }
    }
}
