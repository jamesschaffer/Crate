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

    init(musicService: MusicServiceProtocol = MusicService(),
         dialStore: CrateDialStore = CrateDialStore()) {
        self.musicService = musicService
        self.dialStore = dialStore
    }

    // MARK: - Public

    /// Generate the initial wall (~100 albums).
    func generateWall() async -> [CrateAlbum] {
        await buildWall(total: 100, excluding: [])
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

        // Step 1: Fetch recently played to extract user's genre preferences.
        let recentlyPlayed = await fetchRecentlyPlayedSafe()
        let userGenreIDs = extractGenreIDs(from: recentlyPlayed)

        // If too few recently played items, redistribute Listening History count.
        if recentlyPlayed.count < 15 {
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
                let perGenre = max(historyCount / max(historyGenres.count, 1), 5)
                for genre in historyGenres {
                    group.addTask {
                        let albums = await self.fetchChartsSafe(genreID: genre.appleMusicID, limit: perGenre)
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
                let perGenre = max(chartsCount / max(chartGenres.count, 1), 5)
                for genre in chartGenres {
                    group.addTask {
                        let albums = await self.fetchChartsSafe(genreID: genre.appleMusicID, limit: perGenre)
                        return (.popularCharts, albums)
                    }
                }
            }

            // New Releases
            if newRelCount > 0 {
                let perGenre = max(newRelCount / max(newReleaseGenres.count, 1), 5)
                for genre in newReleaseGenres {
                    group.addTask {
                        let albums = await self.fetchNewReleasesSafe(genreID: genre.appleMusicID, limit: perGenre)
                        return (.newReleases, albums)
                    }
                }
            }

            // Wild Card
            if wildCount > 0 {
                let perGenre = max(wildCount / max(wildCardGenres.count, 1), 5)
                for genre in wildCardGenres {
                    group.addTask {
                        let albums = await self.fetchChartsSafe(genreID: genre.appleMusicID, limit: perGenre)
                        return (.wildCard, albums)
                    }
                }
            }

            for await (signal, albums) in group {
                buckets[signal, default: []].append(contentsOf: albums)
            }
        }

        // Step 4: Deduplicate across all buckets.
        var seenIDs = excluding
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

        // Step 5: Weighted interleave.
        return weightedInterleave(buckets: buckets, weights: weights)
    }

    // MARK: - Weighted Interleave

    /// Interleave albums from signal buckets so higher-weighted signals appear more
    /// frequently but aren't clustered together in long runs.
    private func weightedInterleave(buckets: [WallSignal: [CrateAlbum]],
                                    weights: CrateDialWeights) -> [CrateAlbum] {
        var queues: [WallSignal: [CrateAlbum]] = [:]
        for signal in WallSignal.allCases {
            queues[signal] = (buckets[signal] ?? []).shuffled()
        }

        var result: [CrateAlbum] = []
        var activeSignals = WallSignal.allCases.filter { !(queues[$0]?.isEmpty ?? true) }

        while !activeSignals.isEmpty {
            // Pick a signal weighted by its dial weight.
            let totalWeight = activeSignals.reduce(0.0) { $0 + (weights.values[$1] ?? 0) }
            guard totalWeight > 0 else { break }

            let roll = Double.random(in: 0..<totalWeight)
            var cumulative = 0.0
            var chosen: WallSignal = activeSignals[0]

            for signal in activeSignals {
                cumulative += weights.values[signal] ?? 0
                if roll < cumulative {
                    chosen = signal
                    break
                }
            }

            if let album = queues[chosen]?.first {
                result.append(album)
                queues[chosen]?.removeFirst()
            }

            activeSignals = WallSignal.allCases.filter { !(queues[$0]?.isEmpty ?? true) }
        }

        return result
    }

    // MARK: - Genre Extraction

    /// Match genre names from recently played albums to our static genre taxonomy IDs.
    private func extractGenreIDs(from albums: [CrateAlbum]) -> Set<String> {
        let allGenreNames = albums.flatMap(\.genreNames)
        var ids: Set<String> = []

        for category in Genres.all {
            // Check top-level genre name match.
            if allGenreNames.contains(where: { $0.localizedCaseInsensitiveContains(category.name) }) {
                ids.insert(category.appleMusicID)
            }
            // Check subcategory name matches.
            for sub in category.subcategories {
                if allGenreNames.contains(where: { $0.localizedCaseInsensitiveContains(sub.name) }) {
                    ids.insert(category.appleMusicID)
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
            return []
        }
    }

    private func fetchRecommendationsSafe(limit: Int) async -> [CrateAlbum] {
        do {
            return try await musicService.fetchRecommendations(limit: limit)
        } catch {
            return []
        }
    }

    private func fetchChartsSafe(genreID: String, limit: Int) async -> [CrateAlbum] {
        do {
            return try await musicService.fetchChartAlbums(genreID: genreID, limit: limit, offset: 0)
        } catch {
            return []
        }
    }

    private func fetchNewReleasesSafe(genreID: String, limit: Int) async -> [CrateAlbum] {
        do {
            return try await musicService.fetchNewReleaseChartAlbums(genreID: genreID, limit: limit, offset: 0)
        } catch {
            return []
        }
    }
}
