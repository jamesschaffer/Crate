import Foundation
import MusicKit

/// Interleave albums from signal buckets so higher-weighted signals appear more
/// frequently but aren't clustered together in long runs.
///
/// Used by both CrateWallService and GenreFeedService.
func weightedInterleave<Signal: Hashable>(
    buckets: [Signal: [CrateAlbum]],
    weights: [Signal: Double]
) -> [CrateAlbum] {
    var queues: [Signal: [CrateAlbum]] = [:]
    for (signal, albums) in buckets {
        queues[signal] = albums.shuffled()
    }

    let allSignals = Array(buckets.keys)
    var result: [CrateAlbum] = []
    var activeSignals = allSignals.filter { !(queues[$0]?.isEmpty ?? true) }

    while !activeSignals.isEmpty {
        let totalWeight = activeSignals.reduce(0.0) { $0 + (weights[$1] ?? 0) }
        guard totalWeight > 0 else { break }

        let roll = Double.random(in: 0..<totalWeight)
        var cumulative = 0.0
        var chosen = activeSignals[0]

        for signal in activeSignals {
            cumulative += weights[signal] ?? 0
            if roll < cumulative {
                chosen = signal
                break
            }
        }

        if let album = queues[chosen]?.first {
            result.append(album)
            queues[chosen]?.removeFirst()
        }

        activeSignals = allSignals.filter { !(queues[$0]?.isEmpty ?? true) }
    }

    return result
}
