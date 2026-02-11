import Foundation
import MusicKit

/// Convert fractional weights to integer counts that sum to `total`.
/// Uses the largest-remainder method so rounding errors don't lose items.
func distributeByWeight<Key: Hashable>(_ weights: [Key: Double], total: Int) -> [Key: Int] {
    let raw = weights.mapValues { $0 * Double(total) }
    var floored = raw.mapValues { Int($0) }
    let assigned = floored.values.reduce(0, +)
    var remainder = total - assigned

    let sorted = raw.sorted { ($0.value - Double(Int($0.value))) > ($1.value - Double(Int($1.value))) }
    for entry in sorted where remainder > 0 {
        floored[entry.key, default: 0] += 1
        remainder -= 1
    }

    return floored
}

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
